/*
    what to download:
    - the "templates" folder in this directory
    - "stb_image.h" from https://github.com/nothings/stb/blob/master/stb_image.h
*/

#include <stdio.h>
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#define BASE_BUFF_SIZE 2000000

typedef struct {
    char *data;
    size_t size;
} buffer_t;

typedef struct {
    FILE *input;
    FILE *output;
    FILE *template;
    char *sharedBufferData;
} objParseResources;

typedef struct {
    unsigned char *data;
    FILE *output;
    FILE *template;
} textureParseResources;

const char *objTemplateFilePath = "templates/obj_template.thing";
const char *textureTemplateFilePath = "templates/texture_template.thing";

void initBuffer(buffer_t *buff, char *data) {
    buff->data = data;
    buff->size = 0;
    data[0] = 0;
}

void appendStrBuffer(buffer_t *buff, const char *str) {
    while (*str != 0) {
        buff->data[buff->size] = *str;
        (buff->size)++;
        str++;
    }

    buff->data[buff->size] = 0;
}

void appendCharBuffer(buffer_t *buff, char c) {
    buff->data[buff->size] = c;
    (buff->size)++;
    buff->data[buff->size] = 0;
}

size_t tokenize(char *str, char **tokens) {
    size_t tokenCount = 0;
    int state = 0;
    char *lastStrAddr;

    while (1) {
        char c = *str;
        int isTerminating = (c == ' ') || (c == '/') || (c == '\n') || (c == 0);

        switch (state) {
        case 0:
            if (!isTerminating) {
                lastStrAddr = str;
                state = 1;
            }    

            break;
        case 1:
            if (isTerminating) {
                *str = 0;
                tokens[tokenCount] = lastStrAddr;
                tokenCount++;
                state = 0;
            }

            break;
        }

        if (c == 0) {
            break;
        }

        str++;
    }

    return tokenCount;
}

int getDataType(const char *str) {
    if (str[0] == 'v') {
        if (str[1] == 0) {
            return 0;
        } else if (str[1] == 't' && str[2] == 0) {
            return 1;
        }
    } else if (str[0] == 'f' && str[1] == 0) {
        return 2;
    }

    return -1;
}

int stampTemplate(FILE *template, FILE *output) {
    if (feof(template)) {
        return 0;
    }

    int state = 0;

    while (1) {
        char c = fgetc(template);

        if (c == EOF) {
            break;
        }

        switch (state) {
        case 0:
            if (c == '\\') {
                state = 1;
            } else {
                fputc(c, output);
            }

            break;
        case 1:
            if (c == 'x') {
                return 1;
            } else if (c == '\\') {
                fputc('\\', output);
            }

            state = 0;
            break;
        }
    };

    return 0;
}

int objParseResourcesInit(objParseResources *resources, const char *inputName) {
    resources->input = fopen(inputName, "r");

    if (resources->input == NULL) {
        printf("failed to open input file\n");
        return 0;
    }

    resources->output = fopen("obj_output.luau", "w");

    if (resources->output == NULL) {
        printf("unable to create obj output file\n");
        return 0;
    }

    resources->template = fopen(objTemplateFilePath, "r");

    if (resources->template == NULL) {
        printf("failed to open obj template file\n");
        return 0;
    }

    resources->sharedBufferData = (char *)malloc(BASE_BUFF_SIZE * 3);

    if (resources->sharedBufferData == NULL) {
        printf("failed to allocate buffer for obj output\n");
        return 0;
    }

    return 1;
}

size_t constructTriangles(buffer_t *faceBuffer, char **args, size_t argsCount) {
    size_t faceCount = 0;

    for (size_t i = 6; i < argsCount - 2; i += 3) {
        appendCharBuffer(faceBuffer, '{');

        for (size_t j = 0; j < 3; j++) {
            appendStrBuffer(faceBuffer, args[j]);
            appendCharBuffer(faceBuffer, ',');
            appendStrBuffer(faceBuffer, args[i - 3 + j]);
            appendCharBuffer(faceBuffer, ',');
            appendStrBuffer(faceBuffer, args[i + j]);
            
            if (j != 3) {
                appendCharBuffer(faceBuffer, ',');
            }
        }

        appendStrBuffer(faceBuffer, "},");
        faceCount++;
    }

    return faceCount;
}

void addVertex(buffer_t *vertexBuffer, char **args, size_t argsCount) {
    appendCharBuffer(vertexBuffer, '{');

    for (size_t i = 0; i < argsCount; i++) {
        appendStrBuffer(vertexBuffer, args[i]);

        if (i != argsCount - 1) {
            appendCharBuffer(vertexBuffer, ',');
        }
    }

    appendStrBuffer(vertexBuffer, "},");
}

int objParseMain(objParseResources *resources, const char *inputName) {
    if (objParseResourcesInit(resources, inputName) == 0) {
        return 0;
    }

    buffer_t vertexBuffer;
    initBuffer(&vertexBuffer, resources->sharedBufferData);
    size_t vertexCount = 0;

    buffer_t uvBuffer;
    initBuffer(&uvBuffer, resources->sharedBufferData + BASE_BUFF_SIZE);

    buffer_t faceBuffer;
    initBuffer(&faceBuffer, resources->sharedBufferData + (BASE_BUFF_SIZE * 2));
    size_t faceCount = 0;

    char buffer[1001];

    while (fgets(buffer, 1000, resources->input) != NULL) {
        char *tokens[500];
        size_t tokenCount = tokenize(buffer, tokens);

        if (tokenCount == 0) {
            continue;
        }

        int dataType = getDataType(tokens[0]);

        if (dataType == -1) {
            continue;
        }

        switch (dataType) {
        case 0:
            if (tokenCount < 4) {
                break;
            }    

            addVertex(&vertexBuffer, &tokens[1], 3);
            vertexCount++;
            break;
        case 1:
            if (tokenCount < 3) {
                break;
            }

            addVertex(&uvBuffer, &tokens[1], 2);
            break;
        case 2:
            if (tokenCount < 10 || (tokenCount % 3) != 1) {
                break;
            }

            faceCount += constructTriangles(&faceBuffer, &tokens[1], tokenCount - 1);
            break;
        }
    }

    //this is so scuffed
    size_t numStack[] = { vertexCount, faceCount };
    size_t *numStackPtr = numStack;
    const char *templateArgs[] = { NULL, vertexBuffer.data, uvBuffer.data, NULL, faceBuffer.data };
    const char **argsPtr = templateArgs;

    while (stampTemplate(resources->template, resources->output)) {
        if (*argsPtr == NULL) {
            fprintf(resources->output, "%u", *numStackPtr);
            numStackPtr++;
        } else {
            fputs(*argsPtr, resources->output);
        }

        argsPtr++;
    }

    return 1;
}

int objParse(const char *inputName) {
    objParseResources resources;
    memset(&resources, 0, sizeof(objParseResources));

    int success = objParseMain(&resources, inputName);
    
    FILE *files[] = { resources.input, resources.output, resources.template };

    for (size_t i = 0; i < 3; i++) {
        if (files[i] != NULL) {
            fclose(files[i]);
        }
    }

    if (resources.sharedBufferData != NULL) {
        free(resources.sharedBufferData);
    }
    
    return success;
}

uint32_t packColor(unsigned char *data) {
    uint32_t result = 0;

    for (int i = 0; i <= 2; i++) {
        result |= (uint32_t)data[i] << (i * 8);
    }

    return result;
}

int textureParseMain(textureParseResources *resources, const char *inputName) {
    int x, y, comp;
    resources->data = stbi_load(inputName, &x, &y, &comp, 3);
    comp = 3;

    if (resources->data == NULL) {
        printf("unable to load image\n");
        return 0;
    }

    resources->template = fopen(textureTemplateFilePath, "r");

    if (resources->template == NULL) {
        printf("unable to open texture template file\n");
        return 0;
    }

    resources->output = fopen("texture_output.luau", "w");

    if (resources->output == NULL) {
        printf("failed to create texture output file\n");
        return 0;
    }

    stampTemplate(resources->template, resources->output);

    int maxIndex = x * y * comp;

    for (int i = 0; i < maxIndex; i += comp) {
        fprintf(resources->output, "%u", packColor(resources->data + i));
        fputc(',', resources->output);
    }

    stampTemplate(resources->template, resources->output);
    fprintf(resources->output, "%d", x);
    stampTemplate(resources->template, resources->output);    
    fprintf(resources->output, "%d", y);
    stampTemplate(resources->template, resources->output);
    return 1;
}

int textureParse(const char *inputName) {
    textureParseResources resources;
    memset(&resources, 0, sizeof(textureParseResources));
    
    int success = textureParseMain(&resources, inputName);
    
    if (resources.data != NULL) {
        stbi_image_free(resources.data);
    }

    if (resources.output != NULL) {
        fclose(resources.output);
    }

    if (resources.template != NULL) {
        fclose(resources.template);
    }
    
    return success;
}

int main(int argc, char **argv) {
    if (argc == 1) {
        printf("command: %s [.obj] [.png/.jpg]\n", argv[0]);
        return 0;
    }

    if (argc != 3) {
        printf("expected 2 arguments (.obj file and image file)");
        return 1;
    }

    if (objParse(argv[1]) == 0) {
        printf("obj parsing failed\n");
        return 1;
    }

    if (textureParse(argv[2]) == 0) {
        printf("texture parsing failed\n");
        return 1;
    }

    printf("exit successful\n");    
    return 0;
}