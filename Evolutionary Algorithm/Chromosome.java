import java.awt.*;
import java.awt.image.BufferedImage;
import java.util.ArrayList;

/**
 * Chromosome consists of genes.
 * To simplify, chromosome represents the image,
 * and each gene represents some part of the image.
 * So, genes are like blocks of pixels on the image,
 * which are placed on some kind of maze.
 * <p>
 * Thus, it is easy to represent the chromosome like a 2d array of blocks,
 * to access a particular gene.
 */
public class Chromosome {

    private final int blockNumbersY;
    private final int blockNumbersX;
    private final int blockSizeY;
    private final int blockSizeX;
    private Double RMSD;
    private BufferedImage image;

    private final ArrayList<ArrayList<Gene>> genes;

    Chromosome(int blockNumbersY, int blockNumbersX, int blockSizeY, int blockSizeX) {
        this.blockNumbersY = blockNumbersY;
        this.blockNumbersX = blockNumbersX;
        this.blockSizeY = blockSizeY;
        this.blockSizeX = blockSizeX;

        genes = new ArrayList<>(blockNumbersY);
        for (int i = 0; i < blockNumbersY; i++) {
            ArrayList<Gene> row = new ArrayList<>(blockNumbersX);
            for (int j = 0; j < blockNumbersX; j++) {
                row.add(generateGene());
            }
            genes.add(row);
        }
    }

    Chromosome(Chromosome chromosome) {
        this.blockNumbersY = chromosome.getBlockNumbersY();
        this.blockNumbersX = chromosome.getBlockNumbersX();
        this.blockSizeY = chromosome.getBlockSizeY();
        this.blockSizeX = chromosome.getBlockSizeX();
        this.RMSD = chromosome.getRMSD();
        this.image = chromosome.getImage();

        ArrayList<ArrayList<Gene>> chromosomeBlocks = chromosome.getGenes();

        genes = new ArrayList<>(blockNumbersY);
        for (int i = 0; i < blockNumbersY; i++) {
            ArrayList<Gene> row = new ArrayList<>(blockNumbersX);
            for (int j = 0; j < blockNumbersX; j++) {
                row.add(new Gene(chromosomeBlocks.get(i).get(j)));
            }
            genes.add(row);
        }
    }

    /**
     * Create the population with mutated gene according to the given chromosome
     *
     * @param chromosome       given chromosome
     * @param amountOfSiblings number of chromosomes with the same mutated gene, but with different other characteristics
     * @return population
     */
    public ArrayList<Chromosome> mutate(Chromosome chromosome, int amountOfSiblings) {

        // Mutate randomly gene
        int blockY = Calculation.getRandomNumber(0, blockNumbersY);
        int blockX = Calculation.getRandomNumber(0, blockNumbersX);
        Gene gene = generateGene();

        // Create siblings with this mutated gene, but different other characteristics
        // generated randomly
        ArrayList<Chromosome> siblings = new ArrayList<>(amountOfSiblings);
        for (int i = 0; i < amountOfSiblings; i++) {
            Gene newGeneColor = new Gene(gene);
            newGeneColor.colorMaze();
            Chromosome child = new Chromosome(chromosome);
            child.setBlock(newGeneColor, blockY, blockX);
            siblings.add(child);
        }

        return siblings;
    }

    /**
     * Calculate the 'image' field of this class
     */
    public void calculateImage(int imageWidth, int imageHeight, int imageType) {
        image = new BufferedImage(imageWidth, imageHeight, imageType);

        // Set the image background
        for (int x = 0; x < imageWidth; x++) {
            for (int y = 0; y < imageHeight; y++) {
                image.setRGB(x, y, new Color(0, 0, 0).getRGB());
            }
        }

        // Add genes on the image
        ArrayList<Pixel> pixels = getPixels(imageWidth, imageHeight);
        for (Pixel pixel : pixels) {
            image.setRGB(pixel.x, pixel.y, pixel.color.getRGB());
        }
    }

    public BufferedImage getImage() {
        return image;
    }

    public void setRMSD(Double RMSD) {
        this.RMSD = RMSD;
    }

    public Double getRMSD() {
        return RMSD;
    }

    public void setBlock(Gene gene, int y, int x) {
        genes.get(y).set(x, gene);
    }

    public Gene getGene(int y, int x) {
        return new Gene(genes.get(y).get(x));
    }

    public ArrayList<ArrayList<Gene>> getGenes() {
        return genes;
    }

    public int getBlockNumbersY() {
        return blockNumbersY;
    }

    public int getBlockNumbersX() {
        return blockNumbersX;
    }

    public int getBlockSizeY() {
        return blockSizeY;
    }

    public int getBlockSizeX() {
        return blockSizeX;
    }

    /**
     * Create randomly the gene
     *
     * @return generated gene
     */
    private Gene generateGene() {
        Gene gene = new Gene(blockSizeY, blockSizeX);
        gene.fillMaze();
        gene.colorMaze();
        return gene;
    }

    /**
     * Interpret the maze of genes in terms of pixels.
     * It scales the paths to image sizes.
     */
    private ArrayList<Pixel> getPixels(int imageWidth, int imageHeight) {
        ArrayList<Pixel> pixels = new ArrayList<>(imageWidth * imageHeight);

        //int offsetY = (imageHeight / (blockNumbersY * blockSizeY)) / 2;
        //int offsetX = (imageWidth / (blockNumbersX * blockSizeX)) / 2;
        int offsetY = 4;
        int offsetX = 4;

        ArrayList<Path> paths = getPaths();
        for (Path path : paths) {
            Color pathColor = path.getColor();
            for (int j = 0; j < path.size() - 1; j++) {
                Cell current = path.get(j);
                Cell next = path.get(j + 1);
                int yStart = Math.min(current.y * offsetY + 1, next.y * offsetY + 2);
                int xStart = Math.min(current.x * offsetX + 1, next.x * offsetX + 2);
                int xStop = Math.max(current.x * offsetX + 1, next.x * offsetX + 2);
                int yStop = Math.max(current.y * offsetY + 1, next.y * offsetY + 2);

                for (int k = yStart; k <= yStop; k++) {
                    for (int l = xStart; l <= xStop; l++) {
                        pixels.add(new Pixel(k, l, pathColor));
                    }
                }
            }

            Cell lastCell = path.get(path.size() - 1);
            int yStart = lastCell.y * offsetY + 1;
            int xStart = lastCell.x * offsetX + 1;
            int yStop = yStart + 1;
            int xStop = xStart + 1;
            for (int k = yStart; k <= yStop; k++) {
                for (int l = xStart; l <= xStop; l++) {
                    pixels.add(new Pixel(k, l, pathColor));
                }
            }
        }

        return pixels;
    }

    /**
     * Get genes patterns
     */
    private ArrayList<Path> getPaths() {
        ArrayList<Path> paths = new ArrayList<>();
        for (int y = 0; y < blockNumbersY; y++) {
            for (int x = 0; x < blockNumbersX; x++) {
                ArrayList<Path> blockPaths = genes.get(y).get(x).getPaths();
                for (Path blockPath : blockPaths) {
                    Path newPath = new Path(blockPath.getColor());
                    for (int j = 0; j < blockPath.size(); j++) {
                        Cell cell = blockPath.get(j);
                        int newY = y * blockSizeY + cell.y;
                        int newX = x * blockSizeX + cell.x;
                        newPath.add(new Cell(newY, newX));
                    }
                    paths.add(newPath);
                }
            }
        }

        return paths;
    }
}
