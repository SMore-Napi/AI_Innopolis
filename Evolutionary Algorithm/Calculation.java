import java.awt.*;
import java.awt.image.BufferedImage;
import java.util.ArrayList;
import java.util.HashSet;

/**
 * Helpful class for common static calculation methods
 */
public class Calculation {

    // Set of colors
    public static ArrayList<Color> colorPalette;

    public static int getRandomNumber(int min, int max) {
        return (int) ((Math.random() * (max - min)) + min);
    }

    /**
     * Calculate RMSD for the whole pixels of images
     */
    public static double calculateRootMeanSquareDeviation(BufferedImage firstImage, BufferedImage secondImage) {
        return calculateRootMeanSquareDeviation(firstImage, secondImage, 0, 0, firstImage.getWidth(), firstImage.getHeight());
    }

    /**
     * Calculate RMSD for the particular block of pixels of images
     */
    public static double calculateRootMeanSquareDeviation(BufferedImage firstImage, BufferedImage secondImage, int startX, int startY, int endX, int endY) {
        double sum = 0;
        for (int x = startX; x < endX; x++) {
            for (int y = startY; y < endY; y++) {
                Color colorFirstImage = new Color(firstImage.getRGB(x, y));
                Color colorSecondImage = new Color(secondImage.getRGB(x, y));

                int redDiff = colorFirstImage.getRed() - colorSecondImage.getRed();
                int greenDiff = colorFirstImage.getGreen() - colorSecondImage.getGreen();
                int blueDiff = colorFirstImage.getBlue() - colorSecondImage.getBlue();

                sum += redDiff * redDiff + greenDiff * greenDiff + blueDiff * blueDiff;
            }
        }
        sum /= ((endX - startX) * (endY - startY));
        sum = Math.sqrt(sum);

        return sum;
    }

    /**
     * Get set of colors which are used in given image
     */
    public static void calculateColorPalette(BufferedImage image) {
        HashSet<Integer> colors = new HashSet<>();
        for (int x = 0; x < image.getWidth(); x++) {
            for (int y = 0; y < image.getHeight(); y++) {
                colors.add(image.getRGB(x, y));
            }
        }

        colorPalette = new ArrayList<>(colors.size());
        for (Integer element : colors) {
            colorPalette.add(new Color(element));
        }
    }

    /**
     * Get randomly color from color palette if it's calculated
     * or just random color otherwise.
     */
    public static Color getRandomColor() {
        if (colorPalette != null) {
            int index = getRandomNumber(0, colorPalette.size());
            return new Color(colorPalette.get(index).getRGB());
        }

        int r = getRandomNumber(0, 256);
        int g = getRandomNumber(0, 256);
        int b = getRandomNumber(0, 256);
        return new Color(r, g, b);
    }
}
