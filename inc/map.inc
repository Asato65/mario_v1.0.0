; 床=A=41 => 00
; レンガ=B=42 => 01
; これはランレングスでなく，オブジェクトの位置を指定して配置した方がいい？

MAP1_1_POS:
	; 1
	;.byte $21	; X 2, Y 1に配置
	.byte $02, $03, $32
	.byte $98
	.byte $a5, $a8
	.byte $b5, $b8
	.byte $c5, $c8
	.byte $d8
	.byte $ef
	; 2
	.byte $46
	.byte $7b
	.byte $8b
	.byte $9b
	.byte $fc
	.byte $ef
	; 3
	.byte $13
	.byte $14
	.byte $4d
	.byte $4e
	.byte $a8
	.byte $ef
	; 4
	.byte $53
	.byte $ef

	.byte $ff

MAP1_1_OBJ:
	.byte BLOCK, BLOCK, BLOCK
	.byte BLOCK	; 42 => レンガ
	.byte BLOCK, QBLOCK
	.byte BLOCK, BLOCK
	.byte BLOCK, QBLOCK
	.byte BLOCK
	.byte $ef
	;2
	.byte BLOCK
	.byte BLOCK
	.byte QBLOCK
	.byte BLOCK
	.byte BLOCK
	.byte $ef
	;3
	.byte BLOCK
	.byte BLOCK
	.byte BLOCK
	.byte BLOCK
	.byte QBLOCK
	.byte $ef
	; 4
	.byte BLOCK
	.byte $ef
	;end
	.byte $ff

MAP1_1_DATA:
	.byte $00	; 地上
	.byte $02	; 画面下


; よって，レンガが(8, 8)に配置される（分割したマップの）
; オブジェクト情報は400~5ff番地に保存する
; 400番台，500番台に入る時にマップ番号を更新