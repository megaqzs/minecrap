// NOTE This Code is an incomplete implementetion of a bsp tree generator
#include "bspgen.h"
int exit_code = 0;
int NodeCount = 0;
int width;
int height;

node *XSplit(int *XSorted, int *YSorted, line *geometry, int len) {
	unsigned short mean = 0;
	unsigned short minY = SHRT_MAX;
	unsigned short maxY = SHRT_MIN;
	for (int i = 0; i < len; i++) {
		mean += geometry[i].start + geometry[i].end;
		if (maxY < geometry[i].start)
			maxY = geometry[i].start;
		if (maxY < geometry[i].end)
			maxY = geometry[i].end;
		if (minY > geometry[i].start)
			minY = geometry[i].start;
		if (minY > geometry[i].end)
			minY = geometry[i].end;
	}
	mean /= 2 * len;
	maxY /= width;
	minY /= width;

	node *head = malloc(sizeof(node));
	//head->right = YSplit()
	//head->left = YSplit()

	return head;
}

node *YSplit(int *XSorted, int *YSorted, line *geometry, int len) {
	unsigned short mean = 0;
	unsigned short minX = SHRT_MAX;
	unsigned short maxX = SHRT_MIN;
	for (int i = 0; i < len; i++) {
		mean += geometry[i].start + geometry[i].end;
		if (maxX < geometry[i].start % width)
			maxX = geometry[i].start % width;
		if (maxX < geometry[i].end % width)
			maxX = geometry[i].end % width;
		if (minX > geometry[i].start % width)
			minX = geometry[i].start % width;
		if (minX > geometry[i].end % width)
			minX = geometry[i].end % width;
	}
	mean /= 2 * len;

	node *head = malloc(sizeof(node));
	//head->right = XSplit()
	//head->left = XSplit()

	return head;
}

int XLineCompIndex(const void *a, const void *b, void *geometry) {
	int a_avg = ((line*)geometry)[*(int*)a].start % width;
	a_avg /= 2;
	int b_avg = ((line*)geometry)[*(int*)b].start % width;
	b_avg /= 2;
	return a_avg - b_avg;
}

int YLineCompIndex(const void *a, const void *b, void *geometry) {
	int a_avg = ((line*)geometry)[*(int*)a].start / width;
	a_avg /= 2;
	int b_avg = ((line*)geometry)[*(int*)b].start / width;
	b_avg /= 2;
	return a_avg - b_avg;
}

void ConnectLine(line *geometry, int Start, int End, char type) {
	if (geometry[End].end != -1 && geometry[End].type == type) {
		geometry[Start].end = geometry[End].end;
		geometry[End].end = -1;
		geometry[End].type = -1;
	} else {
		geometry[Start].end = End;
	}
	geometry[Start].type = type;
}

void getYLines(cJSON *tile, line *lines) {
	for (int i = 0; i <  width * height; i++) {
		int value = tile->valueint - 1;
		if (value < 1) {
			tile = tile->next;
			continue;
		}
		char type = value >> 4;
		if (value&2)
			ConnectLine(lines, i+width, i, type);
		if (value&8)
			ConnectLine(lines, i+width+1, i+1, type);
		tile = tile->next;
	}
}

void getXLines(cJSON *tile, line *lines) {
	for (int i = 0; i < width * height; i++) {
		int value = tile->valueint - 1;
		if (value < 1) {
			tile = tile->next;
			continue;
		}
		char type = value >> 4;
		if (value&1)
			ConnectLine(lines, i+1, i, type);
		if (value&4)
			ConnectLine(lines, i+width+1, i+width, type);
		tile = tile->next;
	}
}

bool TilesetToGeometry(cJSON *tile, line **geometry, size_t *LineCount) {
	__label__ error;

	line *YLines = NULL;
	line *XLines = NULL;
	*geometry = NULL;

	YLines = calloc((width+1)*(height+1), sizeof(line));
	if (YLines == NULL)
		goto error;

	memset(YLines, -1, sizeof(line) * (width+1)*(height+1));
	getYLines(tile, YLines);

	int YLen = 0;
	for (int i = 0; i < (width+1)*(height+1); i++) {
		if (YLines[i].end != -1) {
			memmove(&YLines[YLen], &YLines[i], sizeof(line));
			YLines[YLen].start = i;
			YLines[YLen].type |= 1 << 7;
			YLen++;
		}
	}

	YLines = reallocarray(YLines, YLen, sizeof(line));
	if (YLines == NULL)
		goto error;

	XLines = calloc((height+1)*(width+1), sizeof(line));
	if (XLines == NULL)
		goto error;

	memset(XLines, -1, sizeof(line) * (height+1)*(width+1));
	getXLines(tile, XLines);

	int XLen = 0;
	for (int i = 0; i < (width+1)*(height+1); i++) {
		if (XLines[i].end != -1) {
			memmove(&XLines[XLen], &XLines[i], sizeof(line));
			XLines[XLen].start = i;
			XLen++;
		}
	}
	XLines = reallocarray(XLines, XLen, sizeof(line));
	if (XLines == NULL)
		goto error;

	if (!(*geometry = calloc(YLen + XLen,  sizeof(line))))
		goto error;
	memcpy(*geometry, YLines, YLen * sizeof(line));
	memcpy(*geometry + YLen * sizeof(line), XLines, XLen * sizeof(line));
	free(XLines);
	free(YLines);
	*LineCount = YLen;

	return true;
error:
		free(YLines);
		free(XLines);
		return false;
}

int main(int argc, char *argv[]) {
	if (argc != 3)
		return -1;

	line *MapGeometry = NULL;
	cJSON *MapJson = NULL;
	int *XSortIndexes = NULL;
	int *YSortIndexes = NULL;

	FILE *map = fopen(argv[1], "r");
	fseek(map, 0, SEEK_END);
	size_t MapStrLen = ftell(map);
	fseek(map, 0, SEEK_SET);
	char *MapStr = malloc(MapStrLen);
	if (MapStr == NULL) {
		fputs("Error there is no available memory", stderr);
		fclose(map);
		goto exit;
	}
	fread(MapStr, sizeof(char), MapStrLen, map);
	MapJson = cJSON_ParseWithLength(MapStr, MapStrLen);
	free(MapStr);
	fclose(map);

	if (MapJson == NULL) {
		const char *error_ptr = cJSON_GetErrorPtr();
		if (error_ptr != NULL) {
			fprintf(stderr, "Error before: %s\n", error_ptr);
		}
		exit_code = -2;
		goto exit;
    }

	cJSON *WidthJson = cJSON_GetObjectItemCaseSensitive(MapJson, "width");
	cJSON *HeightJson = cJSON_GetObjectItemCaseSensitive(MapJson, "height");
	cJSON *LayersJson = cJSON_GetObjectItemCaseSensitive(MapJson, "layers");

	width = WidthJson->valueint;
	height = HeightJson->valueint;
	if (!cJSON_IsNumber(HeightJson) || !cJSON_IsNumber(WidthJson) || !cJSON_IsArray(LayersJson)) {
		fputs("Error the json map file is corrupted\n", stderr);
		exit_code = -2;
		goto exit;
	}

	// TODO: check if data type is incorrect
	cJSON *tileset = cJSON_GetObjectItemCaseSensitive(LayersJson->child, "data");
	size_t LineCount;
	if (!TilesetToGeometry(tileset->child, &MapGeometry, &LineCount))
		goto exit;
	for (int i = 0; i < LineCount; i++)
		printf("{%i, %i}, ", MapGeometry[i].start, MapGeometry[i].end);

	XSortIndexes = calloc(LineCount, sizeof(int));
	YSortIndexes = calloc(LineCount, sizeof(int));
	if (!XSortIndexes || !YSortIndexes)
		goto exit;

	for (int i = 0; i < LineCount; i++)
		XSortIndexes[i] = i;

	memcpy(YSortIndexes, XSortIndexes, LineCount);
	qsort_r(XSortIndexes, LineCount, sizeof(int), XLineCompIndex, MapGeometry);
	qsort_r(YSortIndexes, LineCount, sizeof(int), YLineCompIndex, MapGeometry);

	//node *head = YSplit(YSortIndexes, XSortIndexes, MapGeometry);

exit:
	cJSON_Delete(MapJson);
	free(MapGeometry);
	free(XSortIndexes);
	free(YSortIndexes);
	return exit_code;
}
