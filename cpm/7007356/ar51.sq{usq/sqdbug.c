/* Debugging aids for SQ and related modules */

#include "bdscio.h"
#include "dio.h"
#include "sqcom.h"
#include "sq.h"

pcounts()
{
	int i;

	if(debug) {
		puts("\nCounts after 1st algorithm and maybe scaling");
		for(i = 0; i < NUMVALS; ++i) {
			if(i%8 == 0)
				printf("\n%4X  ", i);
			printf("%5u  ", node[i].weight);
		}
	puts("\n\n");
	}
}

phuff()
{
	int i;

	if(debug) {
		printf("\nEncoding tree - root=%3d\n", dctreehd);
		for(i = 0; i < NUMNODES; ++i)
			if(node[i].weight != 0)
				printf("%3d  w=%5u d=%3d l=%3d r=%3d\n", i, node[i].weight, node[i].tdepth, node[i].lchild, node[i].rchild);

		printf("\nHuffman codes\n");
		for(i = 0; i < NUMVALS; ++i) {
			if(codelen[i] > 0)
				printf("%3d  %4X l=%2d c=%4x\n", i, i, codelen[i], code[i]);
		}
	}
}
