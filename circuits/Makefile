TEMPLATES := $(wildcard main_*.template)
CIRCOMS := $(TEMPLATES:template=circom)
N := 4
L := 1
T := (1<<32)
Q1 := (1<<56)
Q2 := 0
Q3 := 0

all: ${CIRCOMS}

main_%.circom: main_%.template 
	@echo Generating ${^:.template=.${N}.circom}
	@gcc -E -P -D"N=${N}" -D"L=${L}" -D"T=${T}" -D"Q1=${Q1}" -D"Q2=${Q2}" -D"Q3=${Q3}" -o ${^:.template=.${N}.circom} - < $^

clean: 
	@rm main_*.circom
