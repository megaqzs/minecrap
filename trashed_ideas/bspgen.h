#define _GNU_SOURCE
#include <stdlib.h>
#include <stdio.h>
#include <cjson/cJSON.h>
#include <string.h>
#include <stdbool.h>
#include <limits.h>

// a node in a kd bsp tree
typedef struct node {
	struct node *right;
	struct node *left;
	unsigned short split; // the location of the split in x (or y if the depth is odd)
	unsigned short min;
	unsigned short max;
	char value;
} node;

// TODO test if int overflows are possible
typedef struct {
	int end;
	int start;
	int index;
	char type;
} line;

node *XSplit(int *XSorted, int *YSorted, line *geometry, int len);
node *YSplit(int *XSorted, int *YSorted, line *geometry, int len);
