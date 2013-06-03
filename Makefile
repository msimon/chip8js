all:
	@ocamlbuild chip8.otarget
	@cp _build/chip8.js public

lauch:
	ocsigenserver -c chip8.conf

sass:
	@compass compile ./css
	@cp ./css/css/chip8.css ./public


clean:
	rm -rf _build
