; ------------------------------------------------------------------------------
; あたり判定
; ------------------------------------------------------------------------------

.scope S_CHECK_COLLISION
	tmp_posX = $d0
	tmp_block_posX = $d1
	tmp_posY = $d2
	tmp_block_posY = $d3
	width = $d4
	height = $d5
	move_amount_block = $d6
	tmp1 = $d7
	tmp2 = $d8
	start_x = $d9
	start_y = $da
	collision_pos = $db
.endscope

S_CHECK_COLLISION:
	lda #$00
	sta S_CHECK_COLLISION::collision_pos
	jsr S_GET_TMP_POS
	lda mario_x_direction
	bne @R
	jsr S_GET_ISCOLLISION_L
	jmp @CHK_Y
@R:
	jsr S_GET_ISCOLLISION_R
@CHK_Y:
	lda mario_isjump
	bne @JUMP
	jsr S_GET_ISCOLLISION_GROUND
	jmp @MOVE
@JUMP:
	jsr S_GET_ISCOLLISION_UP

@MOVE:

	rts  ; -----------------------------


; ------------------------------------------------------------------------------
; 左あたり判定チェック
; ------------------------------------------------------------------------------

S_GET_ISCOLLISION_L:
	ldx S_CHECK_COLLISION::tmp_block_posX
	ldy S_CHECK_COLLISION::tmp_block_posY
	jsr S_GET_ISBLOCK					; TODO: x, yレジスタを破壊しない
	beq @NOCOLLISION_LEFT
	lda #%1000							; 左上
	ora S_CHECK_COLLISION::collision_pos
	sta S_CHECK_COLLISION::collision_pos
@NOCOLLISION_LEFT:
	; あたり判定の幅が10H以外の大きな敵の時の動作（まだ組んでない）
	; lda S_CHECK_COLLISION::height
	; cmp #$11
	; bpl @SKIP
	lda S_CHECK_COLLISION::tmp_posY
	and #%11110000
	cmp #$e0
	bpl @NOCOLLISION
	; tmpPos+height > (tmpPos&F0H)+10H　ならもう一つブロックチェック
	; これを変形して　(tmpPos&F0H)+10H-height < tmpPos
	; よって　(tmpPos&F0H)+10H-height >= tmpPos ならスキップ
	add #$10
	sub S_CHECK_COLLISION::height
	cmp S_CHECK_COLLISION::tmp_posY
	bpl @NOCOLLISION
	iny
	jsr S_GET_ISBLOCK
	beq @NOCOLLISION
	lda #%0010							; 左下
	ora S_CHECK_COLLISION::collision_pos
	sta S_CHECK_COLLISION::collision_pos
@NOCOLLISION:
	rts  ; -----------------------------


; ------------------------------------------------------------------------------
; 右あたり判定チェック
; ------------------------------------------------------------------------------

S_GET_ISCOLLISION_R:
	ldx S_CHECK_COLLISION::tmp_block_posX
	inx
	ldy S_CHECK_COLLISION::tmp_block_posY
	jsr S_GET_ISBLOCK
	beq @NOCOLLISION_RIGHT
	lda #%0100							; 右上
	ora S_CHECK_COLLISION::collision_pos
	sta S_CHECK_COLLISION::collision_pos
	rts  ; -----------------------------
@NOCOLLISION_LEFT:
	lda S_CHECK_COLLISION::tmp_posY
	and #%11110000
	cmp #$e0
	bpl @NOCOLLISION
	add #$10
	sub S_CHECK_COLLISION::height
	cmp S_CHECK_COLLISION::tmp_posY
	bpl @NOCOLLISION
	iny
	jsr S_GET_ISBLOCK
	beq @NOCOLLISION
	lda #%0001							; 右下
	ora S_CHECK_COLLISION::collision_pos
	sta S_CHECK_COLLISION::collision_pos
@NOCOLLISION:
	rts  ; -----------------------------


; ------------------------------------------------------------------------------
; 下あたり判定チェック
; ------------------------------------------------------------------------------

S_GET_ISCOLLISION_GROUND:
	ldx S_CHECK_COLLISION::tmp_block_posX
	ldy S_CHECK_COLLISION::tmp_block_posY
	iny
	jsr S_GET_ISBLOCK
	beq @NOCOLLISION_GROUND
	lda #%0010							; 左下
	ora S_CHECK_COLLISION::collision_pos
	sta S_CHECK_COLLISION::collision_pos
@NOCOLLISION_GROUND:
	lda S_CHECK_COLLISION::tmp_posX
	add #$10
	sub S_CHECK_COLLISION::width
	cmp S_CHECK_COLLISION::tmp_posX
	bpl @NOCOLLISION
	inx
	jsr S_GET_ISBLOCK
	beq @NOCOLLISION
	lda #%0001							; 右下
	ora S_CHECK_COLLISION::collision_pos
	sta S_CHECK_COLLISION::collision_pos
@NOCOLLISION:
	rts  ; -----------------------------


; ------------------------------------------------------------------------------
; 上あたり判定チェック
; ------------------------------------------------------------------------------

S_GET_ISCOLLISION_UP:
	ldx S_CHECK_COLLISION::tmp_block_posX
	ldy S_CHECK_COLLISION::tmp_block_posY
	jsr S_GET_ISBLOCK
	beq @NOCOLLISION_UP
	lda #%1000							; 左上
	ora S_CHECK_COLLISION::collision_pos
	sta S_CHECK_COLLISION::collision_pos
@NOCOLLISION_UP:
	lda S_CHECK_COLLISION::tmp_posX
	add #$10
	sub S_CHECK_COLLISION::width
	cmp S_CHECK_COLLISION::tmp_posX
	bpl @NOCOLLISION
	inx
	jsr S_GET_ISBLOCK
	beq @NOCOLLISION
	lda #%0100							; 右上
	ora S_CHECK_COLLISION::collision_pos
	sta S_CHECK_COLLISION::collision_pos
@NOCOLLISION:
	rts  ; -----------------------------


; ------------------------------------------------------------------------------
; 引数の座標のブロック判定
; 引数：X, YレジスタにブロックのX, Y座標
; 破壊：Aレジスタ（X, Y破壊しない）
; 戻り値：無し
; ------------------------------------------------------------------------------

S_GET_ISBLOCK:
	lda S_CHECK_COLLISION::move_amount_disp
	cpx #$10
	bmi @NOINCDISP
	eor #%00000001						; +1する→下位1bit変化
@NOINCDISP:
	and #%00000001
	add #$04
	sta addr_upper
	txa
	lsft4
	sta addr_lower
	tya
	ora addr_lower
	sta addr_lower
	sty S_CHECK_COLLISION::tmp1
	ldy #$00
	lda (addr_lower), y
	ldy S_CHECK_COLLISION::tmp1
	; ブロックにあたり判定があるか
	cmp #$00
	beq @NOCOLLISION
	lda #$01
	rts  ; -----------------------------
@NOCOLLISION:
	lda #$00
	rts  ; -----------------------------


; ------------------------------------------------------------------------------
; 仮座標やブロック座標、左端修正を行う
; 引数無し
; A, X, Yレジスタ破壊
; 戻り値無し
; ------------------------------------------------------------------------------

S_GET_TMP_POS:
	lda mario_x_direction
	bne @SKIP_FIX_OVER_L
	lda mario_posx
	cmp mario_pixel_speed
	bpl @SKIP_FIX_OVER_L
	sta mario_pixel_speed				; 左端修正
@SKIP_FIX_OVER_L:
	lda move_amount_sum
	add S_CHECK_COLLISION::start_x
	ldx mario_x_direction				; 分岐用
	bne @R
	sub mario_pixel_speed
	sta S_CHECK_COLLISION::move_amount_sum
	bcs @STORE_MOVE_AMOUNT
	ldx move_amount_disp
	dex
	stx S_CHECK_COLLISION::move_amount_disp
	jmp @STORE_MOVE_AMOUNT
@R:
	add mario_pixel_speed
	sta S_CHECK_COLLISION::move_amount_sum
	bcc @STORE_MOVE_AMOUNT
	ldx move_amount_disp
	inx
	stx S_CHECK_COLLISION::move_amount_disp
@STORE_MOVE_AMOUNT:
	lda S_CHECK_COLLISION::move_amount_sum		; 以前のtmp_posXと同じ
	rsft4
	sta S_CHECK_COLLISION::move_amount_block

	lda mario_posy
	add ver_speed
	add ver_pos_fix_val
	add S_CHECK_COLLISION::start_y
	sta S_CHECK_COLLISION::tmp_posY
	rsft4
	sta S_CHECK_COLLISION::tmp_block_posY

	rts  ; -----------------------------