NAME=OutpostPlanner_0.6.0

all: $(NAME).zip

$(NAME).zip: *
	rm -f $(NAME).zip
	cd ..; find $(NAME)/ -type f -not -path "*\.git/*" -not -name "\.git" -not -name "makefile" -not -name ".editorconfig | xargs zip $(NAME)/$(NAME).zip 

.PHONY: clean

clean:
	rm -f $(NAME).zip
