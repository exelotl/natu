
@{{BLOCK(coin)

@=======================================================================
@
@	coin, 16x64@4, 
@	+ palette 16 entries, not compressed
@	+ 16 tiles not compressed
@	Total size: 32 + 512 = 544
@
@	Time-stamp: 2020-01-14, 12:34:26
@	Exported by Cearn's GBA Image Transmogrifier, v0.8.15
@	( http://www.coranac.com/projects/#grit )
@
@=======================================================================

	.section .rodata
	.align	2
	.global coinTiles		@ 512 unsigned chars
	.hidden coinTiles
coinTiles:
	.word 0x11100000,0x22211000,0x22222100,0x33322210,0x44434210,0x44443441,0x44443441,0x44443441
	.word 0x00000111,0x00011222,0x00122222,0x01222333,0x01243444,0x14434444,0x14434444,0x14434444
	.word 0x44443441,0x44443441,0x44444431,0x44423310,0x22233310,0x33333100,0x33311000,0x11100000
	.word 0x14434444,0x14434444,0x13444444,0x01332444,0x01333222,0x00133333,0x00011333,0x00000111
	.word 0x11000000,0x22100000,0x22210000,0x44210000,0x24421000,0x22421000,0x22421000,0x22421000
	.word 0x00000011,0x00000122,0x00001222,0x00001242,0x00014442,0x00014442,0x00013442,0x00013442
	.word 0x22421000,0x22421000,0x22421000,0x24241000,0x22410000,0x33310000,0x33100000,0x11000000
	.word 0x00013442,0x00013342,0x00013342,0x00013342,0x00001334,0x00001333,0x00000133,0x00000011

	.word 0x10000000,0x21000000,0x21000000,0x21000000,0x41000000,0x41000000,0x41000000,0x41000000
	.word 0x00000001,0x00000012,0x00000012,0x00000012,0x00000014,0x00000014,0x00000013,0x00000013
	.word 0x41000000,0x31000000,0x31000000,0x31000000,0x31000000,0x31000000,0x31000000,0x10000000
	.word 0x00000013,0x00000013,0x00000013,0x00000013,0x00000013,0x00000013,0x00000013,0x00000001
	.word 0x11000000,0x22100000,0x22210000,0x42210000,0x34221000,0x34221000,0x34221000,0x34421000
	.word 0x00000011,0x00000142,0x00001444,0x00001333,0x00013333,0x00013333,0x00013433,0x00013433
	.word 0x34421000,0x34421000,0x34441000,0x34441000,0x33410000,0x33310000,0x33100000,0x11000000
	.word 0x00013433,0x00013433,0x00013433,0x00013343,0x00001333,0x00001333,0x00000133,0x00000011

	.section .rodata
	.align	2
	.global coinPal		@ 32 unsigned chars
	.hidden coinPal
coinPal:
	.hword 0x0000,0x0842,0x77BE,0x0DBD,0x1EFE,0x0000,0x0000,0x0000
	.hword 0x0421,0x0421,0x0421,0x0421,0x0421,0x0421,0x0421,0x0421

@}}BLOCK(coin)