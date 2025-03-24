.PHONY: clean

all: main.pdf

main.pdf: *.tex
	latexmk -gg -lualatex main.tex

clean:
	latexmk -C
	git clean -df

install: main.pdf
	cp main.pdf $$out
