/**
 * The representation of the cell in the maze
 */
public class Cell {
    int y;
    int x;

    Cell(int y, int x) {
        this.y = y;
        this.x = x;
    }

    public Cell(Cell cell) {
        this.y = cell.y;
        this.x = cell.x;
    }

    @Override
    public boolean equals(Object obj) {
        if (obj == null) {
            return false;
        }
        if (obj.getClass() != Cell.class) {
            return false;
        }
        Cell cell = (Cell) obj;
        return (cell.y == y) && (cell.x == x);
    }

    @Override
    public String toString() {
        return "[" + y + ", " + x + "]";
    }
}
