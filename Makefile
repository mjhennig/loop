##
# Mathias J. Hennig wrote this script. As long as you retain this notice
# you can do whatever you want with this stuff. If we meet some day, and
# you think this stuff is worth it, you can buy me a beer in return.
##

##
# Where to store the install manifest
MANIFEST = ./.install_manifest

##
# A path to prepend before the installation paths
ifeq "$(PREFIX)" ""
PREFIX = /usr/local
endif

##
# Common, official targets
##

test: ./loop.sh
	which bc dd getopt printf sleep stty
	chmod +x ./loop.sh
	test x3 = "x`./loop.sh -i 3 echo 'Hello World!' | wc -l`"
	test "`wc -l < ./loop.sh`" = \
		"`./loop.sh -r echo \\\$$LINE < ./loop.sh | wc -l`"
	test ! -z "`./loop.sh -r echo \\\$$LINE < ./loop.sh`"
	./loop.sh -f exit 1 && exit 1 || :
	./loop.sh -d 1 -i 1 :

install:
	mkdir -p "$(PREFIX)/bin" "$(PREFIX)/man/man1"
	cp ./loop.sh "$(PREFIX)/bin/loop" 
	echo "$(PREFIX)/bin/loop" > $(MANIFEST)
	cp ./loop.1 "$(PREFIX)/man/man1/loop.1"
	echo "$(PREFIX)/man/man1/loop.1" >> $(MANIFEST)
	chmod +x "$(PREFIX)/bin/loop"

uninstall: $(MANIFEST)
	xargs rm < $(MANIFEST)
	rm $(MANIFEST)

##
# Unofficial targets
##

loop-%.tar.gz: ./README ./Makefile ./loop.sh ./loop.1
	test -e "loop-$*" || ( mkdir "loop-$*" && cp $^ "loop-$*" )
	tar -cvzf "loop-$*.tar.gz" "loop-$*"

loop-%.zip: ./README ./Makefile ./loop.sh ./loop.1
	test -e "loop-$*" || ( mkdir "loop-$*" && cp $^ "loop-$*" )
	zip -r "loop-$*.zip" "loop-$*"

clean:
	find . -type d -name 'loop-*' | xargs rm -rf

distclean:
	rm -rf loop-* $(MANIFEST)

