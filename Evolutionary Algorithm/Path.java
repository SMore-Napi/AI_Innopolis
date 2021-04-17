import java.awt.*;
import java.util.ArrayList;

/**
 * The gene consist of paths, some kind of patterns on the maze.
 * The path consists of cells on the maze.
 * We can move along the path by cells only in the following directions:
 * up, down, left, right
 * <p>
 * All cells of the path have the same color.
 */
public class Path {
    private final ArrayList<Cell> path;
    private Color color;

    public Path(Cell start) {
        this.path = new ArrayList<>();
        this.path.add(start);
    }

    public Path(Color color) {
        this.path = new ArrayList<>();
        this.color = color;
    }

    public Path(Path path) {
        this.path = new ArrayList<>();
        color = path.getColor();
        for (int i = 0; i < path.size(); i++) {
            Cell cell = path.get(i);
            this.path.add(new Cell(cell));
        }
    }

    public void add(Cell cell) {
        path.add(new Cell(cell));
    }

    public Cell get(int index) {
        return path.get(index);
    }

    public int size() {
        return path.size();
    }

    public void setColor(Color color) {
        this.color = color;
    }

    public Color getColor() {
        return this.color;
    }
}
