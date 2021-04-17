import java.util.ArrayList;

/**
 * The gene is the part of the chromosome.
 * On the result image representation the gene
 * is the block of pixels on the image.
 * This block contains the patterns.
 * In particular, the patterns are the paths
 * which were calculated by running the Self-Avoiding algorithm
 * (except this algorithm representation doesn't have the goal to fill the maze fully).
 * <p>
 * In other words, the gene is the block of pixels
 * which represents the maze of paths.
 */
public class Gene {
    private final int blockSizeY;
    private final int blockSizeX;
    private Double RMSD;
    private ArrayList<Path> paths;

    Gene(int blockSizeY, int blockSizeX) {
        this.blockSizeY = blockSizeY;
        this.blockSizeX = blockSizeX;
        this.paths = new ArrayList<>();
    }

    Gene(Gene gene) {
        this.blockSizeY = gene.getBlockSizeY();
        this.blockSizeX = gene.getBlockSizeX();
        this.RMSD = gene.getRMSD();
        ArrayList<Path> blockPaths = gene.getPaths();

        this.paths = new ArrayList<>();
        for (Path path : blockPaths) {
            this.paths.add(new Path(path));
        }
    }

    /**
     * Create paths for the gene
     */
    public void fillMaze() {
        ArrayList<Cell> visitedCells = new ArrayList<>(blockSizeY * blockSizeX);
        ArrayList<Cell> unVisitedCells = new ArrayList<>(blockSizeY * blockSizeX);
        for (int i = 0; i < blockSizeY; i++) {
            for (int j = 0; j < blockSizeX; j++) {
                unVisitedCells.add(new Cell(i, j));
            }
        }
        this.paths = new ArrayList<>();

        while (visitedCells.size() != blockSizeY * blockSizeX) {
            int randomUnVisitedCellIndex = Calculation.getRandomNumber(0, unVisitedCells.size());
            Cell unVisitedCell = unVisitedCells.get(randomUnVisitedCellIndex);
            Path newPath = generatePath(unVisitedCell, visitedCells, unVisitedCells);
            paths.add(newPath);
        }
    }

    public void colorMaze() {
        for (Path path : paths) {
            path.setColor(Calculation.getRandomColor());
        }
    }

    public void setRMSD(Double RMSD) {
        this.RMSD = RMSD;
    }

    public Double getRMSD() {
        return RMSD;
    }

    public int getBlockSizeY() {
        return blockSizeY;
    }

    public int getBlockSizeX() {
        return blockSizeX;
    }

    public ArrayList<Path> getPaths() {
        return new ArrayList<>(paths);
    }

    /**
     * Calculate the path by running the Self-Avoiding algorithm
     * (except this algorithm representation doesn't have the goal to fill the maze fully).
     */
    private Path generatePath(Cell startCell, ArrayList<Cell> visitedCells, ArrayList<Cell> unVisitedCells) {
        Path path = new Path(new Cell(startCell));
        visitedCells.add(new Cell(startCell));
        unVisitedCells.remove(startCell);

        while (true) {
            Cell head = path.get(path.size() - 1);
            Cell newHead = getRandomMove(head, visitedCells);
            if (newHead == null) {
                break;
            }
            visitedCells.add(new Cell(newHead));
            unVisitedCells.remove(newHead);
            path.add(newHead);
        }

        return path;
    }

    private Cell getRandomMove(Cell current, ArrayList<Cell> visitedCells) {
        ArrayList<Cell> availableMoves = new ArrayList<>(4);

        Cell cell1 = new Cell(current.y + 1, current.x);
        if (isValidCell(cell1, visitedCells)) {
            availableMoves.add(cell1);
        }
        Cell cell2 = new Cell(current.y - 1, current.x);
        if (isValidCell(cell2, visitedCells)) {
            availableMoves.add(cell2);
        }
        Cell cell3 = new Cell(current.y, current.x + 1);
        if (isValidCell(cell3, visitedCells)) {
            availableMoves.add(cell3);
        }
        Cell cell4 = new Cell(current.y, current.x - 1);
        if (isValidCell(cell4, visitedCells)) {
            availableMoves.add(cell4);
        }

        if (availableMoves.size() == 0) {
            return null;
        }
        return availableMoves.get((int) (Math.random() * availableMoves.size()));
    }

    private boolean isValidCell(Cell cell, ArrayList<Cell> visitedCells) {
        if (cell.x < 0 || cell.y < 0 || cell.x >= blockSizeX || cell.y >= blockSizeY) {
            return false;
        }
        return !visitedCells.contains(cell);
    }
}
