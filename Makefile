DIRS := src

.PHONY: all $(DIRS) main.pdf preview clean

main.pdf: src
	cp src/main.pdf .

all: $(DIRS)

$(DIRS):
	+$(MAKE) -C $@

preview: previews
	"${HOME}"/.iterm2/imgcat thumb01.png combined1.png combined2.png combined3.png thumb08.png

previews: main.pdf
	gs -sDEVICE=png16m -o thumb'%02d'.png -r144 main.pdf
	convert -background '#000' +smush 5 'thumb02.png' 'thumb03.png' combined1.png
	convert -background '#000' +smush 5 'thumb04.png' 'thumb05.png' combined2.png
	convert -background '#000' +smush 5 'thumb06.png' 'thumb07.png' combined3.png

clean:
	+$(MAKE) -C src $@
