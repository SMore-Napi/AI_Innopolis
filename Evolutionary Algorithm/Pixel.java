import java.awt.*;

/**
 * Pixel of the image
 */
class Pixel {
    int y;
    int x;
    Color color;

    Pixel(int y, int x, Color color) {
        this.y = y;
        this.x = x;
        this.color = color;
    }

    @Override
    public String toString() {
        return "[" + x + ", " + y + "]";
    }
}