# Runs in WSL if Windows Developer mode is enabled (non-admin symlink creation)
# Run from parent directory
NAME=OutpostPlanner
# Has to be in same directory, uses relative paths because WSL symlink wierdness
FACTORIO_FOLDER=Factorio_0.18.6
VERSION=$(shell grep '"version":' ${NAME}/info.json | grep -oP '\d+\.\d+\.\d+')
FILE_PATTERNS=${NAME}/**.lua\
${NAME}/locale/*/*.cfg\
${NAME}/graphics/*\
${NAME}/info.json\
${NAME}/LICENSE.txt\
${NAME}/README.md\
${NAME}/thumbnail.png

.PHONY: link clean build

build: clean
	zip ${FACTORIO_FOLDER}/mods/${NAME}_${VERSION}.zip ${FILE_PATTERNS}

link: clean
	cd ${FACTORIO_FOLDER}/mods && ln -s ../../${NAME} ${NAME}_${VERSION}

clean:
	rm -f ${FACTORIO_FOLDER}/mods/${NAME}_*
