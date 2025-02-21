# Nombre del archivo fuente sin extensión
SRC_PLL = poker_llamadas.c
OUT_PLL = $(basename $(SRC_PLL))
SRC_ES = E_S_fichero.c
OUT_ES = $(basename $(SRC_ES))
PROGS = $(OUT_PLL)_32 $(OUT_PLL)_64 $(OUT_ES) 

# Verificación de bibliotecas necesarias
CHECK_LIB32 = dpkg-query -W -f='${Status}' libc6-dev-i386 | grep -c "ok installed"

# Compilador y flags
CC = gcc

.PHONY: all clean       # estos no son ficheros

all: check_libs $(PROGS)

# Verifica e instala dependencias si es necesario
check_libs:
	@echo "🔍 Verificando dependencias..."
	@if [ `$(CHECK_LIB32)` -eq 0 ]; then \
		echo "⚠️  Falta libc6-dev-i386, instalando..."; \
		sudo apt update && sudo apt install -y libc6-dev-i386 gcc-multilib; \
	fi
	@echo "✅ Todas las dependencias están instaladas."

# Compilar en 64 bits
$(OUT_PLL)_64 : $(SRC_PLL)
	@echo "⚙️  Compilando en 64 bits..."
	$(CC) -o $@ $<  
	@echo "✅ Compilado: $(OUT_64)"

# Compilar en 32 bits
$(OUT_PLL)_32 : $(SRC_PLL)
	@echo "⚙️  Compilando en 32 bits..."
	$(CC) -m32 -o $@ $<  
	@echo "✅ Compilado: $(OUT_32)"

# Compilar E_S_fichero.c
$(OUT_ES) : $(SRC_ES)
	@echo "⚙️  Compilando " $(SRC_ES)
	$(CC) -o $@ $<  
	@echo "✅ Compilado: $(OUT_32)"


# Limpieza
clean:
	@echo "🧹 Eliminando archivos compilados..."
	rm -f $(PROGS)
	@echo "✅ Limpieza completa."