NAME=OutpostPlanner_0.1.4

all: $(NAME).zip

$(NAME).zip: *
	rm -f $(NAME).zip
	cd ..; find $(NAME)/ -type f -not -path "*\.git/*" -not -name "\.git" -not -name "makefile" | xargs zip $(NAME)/$(NAME).zip 

.PHONY: clean

clean:
	rm -f $(NAME).zip
