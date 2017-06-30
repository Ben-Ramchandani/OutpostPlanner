NAME=MinePlanner_0.1.0

all: $(NAME).zip

$(NAME).zip:
	find . -not -path "*\.git/*" -not -name "\.git" -not -name "makefile" -not -name "\." | xargs zip -r $(NAME).zip

.PHONY: clean

clean:
	rm -f $(NAME).zip
