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
.endscope

S_CHECK_COLLISION:
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
	beq @SKIP1
	dex
	ldy S_CHECK_COLLISION::tmp_block_posY
	jsr S_GET_ISBLOCK

	rts  ; -----------------------------


; ------------------------------------------------------------------------------
; 右あたり判定チェック
; ------------------------------------------------------------------------------

S_GET_ISCOLLISION_R:

	rts  ; -----------------------------


; ------------------------------------------------------------------------------
; 下あたり判定チェック
; ------------------------------------------------------------------------------

S_GET_ISCOLLISION_GROUND:

	rts  ; -----------------------------


; ------------------------------------------------------------------------------
; 上あたり判定チェック
; ------------------------------------------------------------------------------

S_GET_ISCOLLISION_UP:

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