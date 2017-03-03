


all: metare


metare: metare.d
	dmd -unittest -main $<


test: metare
	./metare

clean:
	@rm -f metare *.o core*


