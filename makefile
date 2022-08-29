

all: mplab-git-help.jar
	copy mplab-git-help.jar ..\Test

clean : 
	del -Y mplab-git-help.jar
	del -Y StoreHex.class
	del -Y buildjar

mplab-git-help.jar : StoreHex.class buildjar
	jar cvf $@ 

%.class : %.java
	javac $^

