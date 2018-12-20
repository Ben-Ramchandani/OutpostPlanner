NAME=OutpostPlanner_1.0.2

all: $(NAME).zip

$(NAME).zip: *
	rm -f $(NAME).zip
	find . -type f -not -path "*\.git/*" -not -name "\.git" -not -name "makefile" -not -name ".editorconfig" | xargs zip $(NAME)/$(NAME).zip 

.PHONY: clean

clean:
	rm -f $(NAME).zip
