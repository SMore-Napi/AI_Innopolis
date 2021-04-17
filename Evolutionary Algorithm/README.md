# Assignment 2. Evolutionary Algorithm

## Description
Write Evolutionary Algorithm to generate 512x512 image by giving a source image using any technique.\
The program was written in Java without including any additional libraries.

### Chromosome representation
The single chromosome represents the set of genes. Each gene contains the pattern on the maze. In particular, the maze contains different lines with different colours. The idea is to print the big colourful maze (labyrinth) which contains small mazes (blocks). The correspondence between the chromosome and image is the following: the image is divided into a grid. The grid cell is the block with a fixed size represented by the gene. So, each gene is responsible for the particular part of the image. The block contains colourful paths. Each path is generated using the Self-Avoiding algorithm. However, in this algorithm version, there is no restriction about fully filling the maze inside the block. So, the path can be of different length. Available moves are the following: up, down, left, right. The Self-Avoiding algorithm continues generating paths until it fills the maze. That is how the block (gene) is formed. Therefore, the image itself will be formed by these blocks (genes) and will represent the chromosome.

### Population size and selection technique
Each generation the mutation to the last chromosome is applied. So, the population contains chromosomes that are different by one mutated gene. However, each chromosome also contains siblings. They have the same mutated gene, but this gene can be different in terms of other parameters. Well, the population of different mutated genes is 250 chromosomes. Each mutated chromosome has 4 siblings. Therefore, the total population size is 250*4 = 1000 mutated chromosomes.
For the selection technique, the fitness function is applied first. Then 100 chromosomes with the best fitness function are selected, which is 10% of the whole population.

### The fitness function
The fitness function is calculated using the Root-Mean-Square Deviation value. The less its value, the more similar the image with the source. It compares pixels from the original and generated images.

### Crossover/mutation
Crossover is done by selecting genes from best descendants which are obtained after the selection technique. Each gene of the chromosome is randomly chosen from one of the descendant chromosomes.
The mutation is done by changing one of the genes from the chromosome. The algorithm randomly chooses the gene and reconstructs it, i.e. generates the new gene and replaces it with the previous one. After that, it provides siblings, which have the same mutated gene, but with different parameters. In image case representation it randomly takes the block (part of the image) and regenerates it using the Self-Avoiding algorithm. The new pattern (set of paths) is the mutated gene. Then siblings have the same paths for this particular block, but each of them will colour paths randomly in a different way.

## Examples
Examples with gifs, videos and statistics can be found in this
[folder](https://github.com/SMore-Napi/AI_Innopolis/tree/main/Evolutionary%20Algorithm/Examples).

### Image 1
<p float="left">
<img width="250" src="Examples/image 1/input.jpg"/>
<img width="250"  src="Examples/image 1/output.jpg"/>
</p>

<img src="https://github.com/SMore-Napi/AI_Innopolis/blob/main/Evolutionary%20Algorithm/Examples/image%201/evolution_gif.gif" width="300" height="300"/>

### Image 2
<p float="left">
<img width="250" src="Examples/image 2/input.jpg"/>
<img width="250"  src="Examples/image 2/output.jpg"/>
</p>

<img src="https://github.com/SMore-Napi/AI_Innopolis/blob/main/Evolutionary%20Algorithm/Examples/image%202/evolution_gif.gif" width="300" height="300" />

## The program
The **Main.java** class contains the entry point: the **main** method which launch the algorithm.\
So, above this method you can find some variables representing parameters for the algorithm.\
The foremost variable is the string **inputImageName**.\
You may specify the name of the source image. By default it is set as *image* without file extension specification.\
You can either put the source file with this name *image.jpg*, or change the **inputImageName** variable.

**Note:**
* The program works only with .jpg files.
* The origin image must be placed in the same folder.

### The way to test the program

To test the program you should install Java and Java JDK.\
Then you need to open the terminal/console.\
Write the following command:
```
cd <path>
```
where *path* is the absolute path to the folder with java files.\
After that you need to compile the code. Simply write the following command:
```
javac Main.java
```

Inside the folder there will be created *.class* files.\
Put the source image with the following name **image.jpg** or with the name which is specified in **inputImageName** variable.\
The final step is to write this command:
```
java Main
```

So, the algorithm will start working.\
There will be created output and statistics folders which contain results.\
Also, inside your terminal/console there will be messages denoting the number of generation.\
To stop the program you can press Ctrl+C.

### Understanding the output
Inside the folder you can find the **output** folder which contains the image for each generation.\
The folder **statistics** contains the data for each generation.\
The same data is outputted in the terminal/console when you run the program.
* **Generation** - stands for the number of the generation
* **Difference** - the difference between current image and the source image. It is calculated using the Root Mean Square Deviation. The less this value - the more similar images.
* **Time** - time moment when the current generation was calculated. It is measured in nanoseconds.

The generation is calculated around 1 minute.\
The program will require around 2GB of RAM.
