import java.awt.image.BufferedImage;
import java.util.ArrayList;
import java.util.Comparator;

public class Evolution {

    /**
     * Populates the population by giving chromosome.
     * The population consists of chromosomes with some mutation.
     * Then it does the selection and crossover.
     * As the result it returns the best chromosome of this population.
     *
     * @param chromosome              basis chromosome
     * @param amountOfPopulations     the number of different chromosomes with one mutated gene
     * @param amountOfSiblings        the number of chromosomes with common mutated gene,
     *                                but which is different in terms of other parameters
     * @param amountOfBestDescendants the number of best chromosomes for the selection
     * @param sourceImage             original image
     * @return best chromosome
     */
    public static Chromosome nextGeneration(Chromosome chromosome, int amountOfPopulations, int amountOfSiblings, int amountOfBestDescendants, BufferedImage sourceImage) {
        // Generate new generation
        ArrayList<Chromosome> population = generatePopulation(chromosome, amountOfPopulations, amountOfSiblings);
        // Selection
        ArrayList<Chromosome> descendants = selection(population, sourceImage, amountOfBestDescendants);
        // Crossover
        return crossover(descendants, sourceImage);
    }

    /**
     * Generate the population with mutated genes according to the given chromosome
     *
     * @param chromosome given chromosome
     * @param amount     number of chromosomes with different mutated genes
     * @param siblings   number of chromosomes with the same mutated gene, but with different other characteristics
     * @return list of population
     */
    private static ArrayList<Chromosome> generatePopulation(Chromosome chromosome, int amount, int siblings) {
        ArrayList<Chromosome> population = new ArrayList<>(amount * siblings + 1);
        population.add(new Chromosome(chromosome));

        for (int i = 0; i < amount; i++) {
            ArrayList<Chromosome> childrenSiblings = chromosome.mutate(chromosome, siblings);
            population.addAll(childrenSiblings);
        }
        return population;
    }

    /**
     * Choose the best descendants of the population
     *
     * @param amountDescendants number of best chromosomes of the given population
     * @return list of best descendants
     */
    private static ArrayList<Chromosome> selection(ArrayList<Chromosome> population, BufferedImage sourceImage, int amountDescendants) {

        // Calculate the Root Mean Square Deviation value for each chromosome
        for (Chromosome chromosome : population) {
            chromosome.calculateImage(sourceImage.getWidth(), sourceImage.getHeight(), sourceImage.getType());
            BufferedImage image = chromosome.getImage();
            double RMSD = Calculation.calculateRootMeanSquareDeviation(sourceImage, image);
            chromosome.setRMSD(RMSD);
        }

        // Sort chromosomes by RMSD value
        Comparator<Chromosome> compareByRMSD = Comparator.comparing(Chromosome::getRMSD);
        population.sort(compareByRMSD);

        // Select best chromosomes according to the RMSD value
        ArrayList<Chromosome> bestDescendants = new ArrayList<>(amountDescendants);
        for (int i = 0; i < amountDescendants; i++) {
            bestDescendants.add(population.get(i));
        }

        return bestDescendants;
    }

    /**
     * Create chromosome by selecting genes from parents.
     * It selects genes randomly from one of the given parent,
     * or, as the heuristic, it can select the best gene of given parents to make the algorithm working faster
     *
     * @param chromosomes parents
     * @param sourceImage original image
     * @return crossover chromosome
     */
    private static Chromosome crossover(ArrayList<Chromosome> chromosomes, BufferedImage sourceImage) {
        Chromosome chromosome = new Chromosome(chromosomes.get(0));

        for (int i = 0; i < chromosome.getBlockNumbersY(); i++) {
            for (int j = 0; j < chromosome.getBlockNumbersX(); j++) {
                // Option 1. Select the gene randomly
                //Block block = getRandomBlock(chromosomes, i, j);

                // Option 2. Select the best gene for the heuristic.
                Gene gene = getBestBlock(chromosomes, sourceImage, i, j);

                chromosome.setBlock(gene, i, j);
            }
        }

        // Calculate fields for the created child chromosome
        chromosome.calculateImage(sourceImage.getWidth(), sourceImage.getHeight(), sourceImage.getType());
        BufferedImage image = chromosome.getImage();
        double RMSD = Calculation.calculateRootMeanSquareDeviation(sourceImage, image);
        chromosome.setRMSD(RMSD);

        return chromosome;
    }

    /**
     * Select the particular gene randomly from given parents
     *
     * @param chromosomes parents
     * @param y           gene y coordinate
     * @param x           gene x coordinate
     * @return gene from one of the parent
     */
    private static Gene getRandomBlock(ArrayList<Chromosome> chromosomes, int y, int x) {
        int chromosomeIndex = Calculation.getRandomNumber(0, chromosomes.size());
        return new Gene(chromosomes.get(chromosomeIndex).getGene(y, x));
    }

    /**
     * Select the best gene from given parents according to the source image.
     *
     * @param chromosomes parents
     * @param sourceImage original image
     * @param y           gene y coordinate
     * @param x           gene x coordinate
     * @return best gene
     */
    private static Gene getBestBlock(ArrayList<Chromosome> chromosomes, BufferedImage sourceImage, int y, int x) {

        int mazeSizeY = sourceImage.getHeight() / chromosomes.get(0).getBlockNumbersY();
        int mazeSizeX = sourceImage.getWidth() / chromosomes.get(0).getBlockNumbersX();

        ArrayList<Gene> genes = new ArrayList<>(chromosomes.size());

        // Calculate Root Mean Square Deviation for each gene
        for (Chromosome chromosome : chromosomes) {
            BufferedImage image = chromosome.getImage();

            int startX = mazeSizeX * x;
            int startY = mazeSizeY * y;
            int endX = mazeSizeX * (x + 1);
            int endY = mazeSizeY * (y + 1);

            double RMSD = Calculation.calculateRootMeanSquareDeviation(sourceImage, image, startX, startY, endX, endY);
            Gene gene = new Gene(chromosome.getGene(y, x));
            gene.setRMSD(RMSD);
            genes.add(gene);
        }

        // Sort genes by RMSD value
        Comparator<Gene> compareByRMSD = Comparator.comparing(Gene::getRMSD);
        genes.sort(compareByRMSD);

        // Return the best gene
        return genes.get(0);
    }
}
