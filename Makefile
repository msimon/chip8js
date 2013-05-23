all:
	@ocamlbuild chip8.otarget
	@cp _build/chip8.js public

lauch:
	ocsigenserver -c chip8.conf

clean:
	rm -rf _build
