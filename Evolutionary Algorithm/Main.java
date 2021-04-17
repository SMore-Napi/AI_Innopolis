import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.PrintWriter;

/**
 * @author Roman Soldatov BS19-02
 * The main class with the main method to test the program
 */
public class Main {
    /**
     * Here you can configure parameters related to EA
     */
    // Image name without extension
    // Supports only .jpg images
    private static final String inputImageName = "image";
    // Number of different chromosomes with one mutated gene
    private static final int amountOfPopulations = 250;
    // Number of chromosomes with common mutated gene,
    // but which is different in terms of other parameters
    private static final int amountOfSiblings = 4;
    // Number of best chromosomes for the selection
    private static final int amountOfBestDescendants = 100;
    // Number of generations
    private static final int amountOfGenerations = 500;

    private static final int blockNumbersY = 16;
    private static final int blockNumbersX = 16;
    private static final int blockSizeY = 8;
    private static final int blockSizeX = 8;

    private static final String inputPath = inputImageName + ".jpg";
    private static final String statisticsPath = "statistics/" + inputImageName + "_statistics.txt";
    private static final String outputPath = "output/" + inputImageName + "/generation_";

    public static void main(String[] args) {
        // Prepare necessary files for the algorithm:
        // create folders and files
        createFolders();
        BufferedImage sourceImage = readSourceImage();
        PrintWriter statisticsFile = createStatisticsFile();

        // Start the algorithm itself
        startEvolutionaryAlgorithm(sourceImage, statisticsFile);

        statisticsFile.close();
    }

    /**
     * Evolutionary algorithm for generating an image with respect to the source image
     *
     * @param sourceImage    reference image
     * @param statisticsFile - file for writing the stats
     */
    private static void startEvolutionaryAlgorithm(BufferedImage sourceImage, PrintWriter statisticsFile) {
        // Start timer
        long startTime = System.nanoTime();

        // Calculate main colors which are used in the source image
        Calculation.calculateColorPalette(sourceImage);

        // Create the blank chromosome
        Chromosome chromosome = new Chromosome(blockNumbersY, blockNumbersX, blockSizeY, blockSizeX);

        // Create generations
        for (int i = 0; i < amountOfGenerations; i++) {
            // Create new population for the next generation
            chromosome = Evolution.nextGeneration(chromosome, amountOfPopulations, amountOfSiblings, amountOfBestDescendants, sourceImage);

            // Save the result: the best chromosome of the new generation
            BufferedImage image = chromosome.getImage();
            saveImage(image, outputPath + (i + 1) + ".jpg");

            // Get time
            long currentTime = System.nanoTime();

            // Save intermediate results
            String result = "Generation: " + (i + 1) + "; Difference: " + chromosome.getRMSD() + "; Time: " + (currentTime - startTime) + ";";
            System.out.println(result);
            statisticsFile.println(result);
            statisticsFile.flush();
        }
    }

    /**
     * Save image by giving the path
     *
     * @param image    - image to save
     * @param filePath - path where to save
     */
    private static void saveImage(BufferedImage image, String filePath) {
        File output = new File(filePath);
        try {
            ImageIO.write(image, "jpg", output);
        } catch (IOException e) {
            System.out.println("File " + filePath + "doesn't exist!");
        }
    }

    /**
     * Create necessary folders for the algorithm, if they don't exist
     */
    private static void createFolders() {
        File file = new File("output/");
        if (!file.exists()) {
            file.mkdir();
        }
        file = new File("output/" + inputImageName + "/");
        if (!file.exists()) {
            file.mkdir();
        }

        file = new File("statistics/");
        if (!file.exists()) {
            file.mkdir();
        }
    }

    /**
     * Read input image file
     *
     * @return BufferedImage object
     */
    private static BufferedImage readSourceImage() {
        BufferedImage sourceImage = null;
        File file = new File(inputPath);
        try {
            sourceImage = ImageIO.read(file);
        } catch (IOException e) {
            System.out.println("File " + inputPath + " doesn't exist!");
        }
        return sourceImage;
    }

    /**
     * Create file to write the statistics (intermediate results)
     *
     * @return reference to the file
     */
    private static PrintWriter createStatisticsFile() {
        PrintWriter statisticsFile = null;
        try {
            statisticsFile = new PrintWriter(statisticsPath);
        } catch (FileNotFoundException e) {
            System.out.println("File " + statisticsPath + " doesn't exist!");
        }
        return statisticsFile;
    }
}