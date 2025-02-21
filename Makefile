# Sencillo Makefile usando una regla "patrón"
# almohadilla para poner comentarios

CC=gcc
PROGS=E_S_fichero poker_llamadas

.PHONY: all clean       # estos no son ficheros

all: $(PROGS)

% : %.c    # cualquier fichero con *.c se va a compilar con el comando de abajo
	$(CC) -o $@ $<      
                        #  $@ es el target (izq), $< el prerrequisito (der) 

clean: 
	rm $(PROGS)
	@echo "Programas borrados"   # la arroba para que no se pinte el comando
