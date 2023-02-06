.scope S_GET_ISCOLLISION
	blockid = $d6
.endscope

; ------------------------------------------------------------------------------
; 当たり判定
; 引数なし
; 戻り値無し
; <動作の流れ>
; 左右チェック
; 上昇中：上チェック
; その他：下チェック
; -----------------------------------------------------------------------------

.scope S_CHECK_COLLISION
	tmp_posX = $d0
	tmp_posY = $d1
	tmp_block_posX = $d2
	tmp_block_posY = $d3
	tmp1 = $d4
	tmp2 = $d5
	block = $d6
	move_amount_sum = $d7				; 仮（破壊しないように）
	move_amount_disp = $d8				; 仮
	save_pixel_speed = $d9
.endscope

S_CHECK_COLLISION:
	;! ここで上／下の衝突があるかチェック
; 	jsr S_GET_MOVE_AMOUNT_X
; 	lda mario_x_direction
; 	bne @SKIP_FIX_OVER_L
; 	jsr S_FIX_OVER_L
; @SKIP_FIX_OVER_L:
	jsr S_GET_TMP_POS
	lda move_amount_sum
	and #%11110000
	sta S_CHECK_COLLISION::tmp_posX
	lsr
	lsr
	lsr
	lsr
	sta S_CHECK_COLLISION::tmp_block_posX
	tax
	ldy S_CHECK_COLLISION::tmp_block_posY
	lda mario_isjump
	beq @CHK_GROUND2

	; ldx S_CHECK_COLLISION::tmp_block_posX
	jsr S_GET_BLOCK
	jsr S_IS_COLLISIONBLOCK
	beq @CHK_UP_R
	lda S_CHECK_COLLISION::tmp_posX
	and #%00001111
	cmp #$08
	bmi @COLLISION_Y
@CHK_UP_R:
	lda S_CHECK_COLLISION::tmp_posX
	and #%00001111
	beq @NOCOLLISION_Y

	inx
	jsr S_GET_BLOCK
	jsr S_IS_COLLISIONBLOCK
	beq @NOCOLLISION_Y
	lda S_CHECK_COLLISION::tmp_posX
	and #%00001111
	cmp #$09
	bpl @COLLISION_Y
	bmi @NOCOLLISION_Y
	; ----------------------------------
@CHK_GROUND2:
	iny
	cpy #$0f
	bpl @NOCOLLISION_Y
	jsr S_GET_ISCOLLISION
	bne @COLLISION_Y
	lda S_CHECK_COLLISION::tmp_posX
	and #%00001111
	beq @NOCOLLISION_Y
	inx
	jsr S_GET_ISCOLLISION
	beq @NOCOLLISION_Y
	bne @COLLISION_Y
@COLLISION_Y:
	lda #$00
	sta order_chk_collision
	beq @CHECK_ISJUMP					; 強制ジャンプ
@NOCOLLISION_Y:
	lda #$01
	sta order_chk_collision
	;!----------------------------------

@CHECK_COLLISION_X:						; X方向チェック
	;jsr S_GET_MOVE_AMOUNT_X
	jsr S_GET_TMP_POS

	lda mario_x_direction
	bne @R
	jsr S_CHK_COLLISION_L
	jmp @END_CHECK_COLLISION_X
@R:
	jsr S_CHK_COLLISION_R

@END_CHECK_COLLISION_X:
	lda order_chk_collision
	bne @CHECK_ISJUMP
	rts  ; -----------------------------
@CHECK_ISJUMP:
	;lda mario_x_direction
	;jsr S_FIX_OVER_L
	;jsr S_GET_MOVE_AMOUNT_X
	jsr S_GET_TMP_POS
	lda mario_isjump
	beq @CHECK_GROUND
	jsr S_CHK_COLLISION_UP
	lda ver_speed
	add ver_pos_fix_val
	add mario_posy
	sta mario_posy

	lda order_chk_collision
	beq @CHECK_COLLISION_X
	rts  ; -----------------------------
@CHECK_GROUND:
	ldx S_CHECK_COLLISION::tmp_block_posX
	ldy S_CHECK_COLLISION::tmp_block_posY
	iny
	cpy #$0f
	bpl @SKIP1
	jsr S_GET_ISCOLLISION
	bne @SKIP2
	lda #$01
	sta mario_isfly
	lda S_CHECK_COLLISION::tmp_posX
	and #%00001111
	beq @SKIP1
	inx
	jsr S_GET_ISCOLLISION
	beq @SKIP1
@SKIP2:									; 下にブロックがあったときの処理
	lda S_CHECK_COLLISION::tmp_posY
	and #%11110000
	sta mario_posy
	ldx #$00
	stx ver_speed_decimal_part
	stx ver_pos_decimal_part
	stx ver_speed
	stx mario_isfly
	lda VER_FORCE_DECIMAL_PART_DATA, X
	sta ver_force_decimal_part
	lda VER_FALL_FORCE_DATA
	sta ver_force_fall
	lda order_chk_collision
	bne @END
	jmp @CHECK_COLLISION_X
@SKIP1:
	lda ver_speed
	add ver_pos_fix_val
	add mario_posy
	sta mario_posy

	lda order_chk_collision
	bne @END
	jmp @CHECK_COLLISION_X
@END:
	rts  ; -----------------------------


; ------------------------------------------------------------------------------
; 左の当たり判定、座標ずらし
; ------------------------------------------------------------------------------

S_CHK_COLLISION_L:
	lda S_CHECK_COLLISION::tmp_posX
	and #%00001111
	beq @END_L
	cmp #$0c
	bmi @END_L
	; 0CH~(0FH)なら
	lda #$00							; mario_x_direction（引数に利用）
	jsr S_CHECK_ISBLOCK_LR
	beq @END_L
	lda move_amount_sum
	and #%11110000
	beq @STR_SPEED						; 0をストアする
	sub move_amount_sum
	cnn
@STR_SPEED:
	sta mario_pixel_speed
	lda brake
	bne @END_L
	lda #$0e
	sta mario_speed_L					; ブレーキ中でなく、ブロックに衝突したときピクセル速度0に
@END_L:
	rts  ; -----------------------------


; ------------------------------------------------------------------------------
; 右の当たり判定、座標ずらし
; ------------------------------------------------------------------------------

S_CHK_COLLISION_R:
	lda S_CHECK_COLLISION::tmp_posX
	and #%00001111
	beq @END_R
	cmp #$05
	bpl @END_R
	; (01H)~04Hなら
	lda #$01
	jsr S_CHECK_ISBLOCK_LR
	beq @END_R
	lda move_amount_sum
	and #%00001111
	beq @STR_SPEED						; すでにブロックにぴったりついている場合
	; ジャンプしたときずれる
	lda move_amount_sum
	and #%11110000
	add #$10
	sub move_amount_sum
@STR_SPEED:
	sta mario_pixel_speed
	lda brake
	bne @END_R
	lda #$0e
	sta mario_speed_R					; ブレーキ中でなく、ブロックに衝突したときピクセル速度0に
@END_R:
	rts  ; -----------------------------


; ------------------------------------------------------------------------------
; ジャンプ時の左右ずらし、ブロックの位置
; 引数なし
; A、X、Yレジスタ破壊
; 戻り値なし
; ------------------------------------------------------------------------------

S_CHK_COLLISION_UP:
	ldx S_CHECK_COLLISION::tmp_block_posX
	ldy S_CHECK_COLLISION::tmp_block_posY
	jsr S_GET_BLOCK
	jsr S_IS_COLLISIONBLOCK
	beq @SKIP1
	lda S_CHECK_COLLISION::tmp_posX
	and #%00001111
	cmp #$08
	bmi @DOWN
	lda #%00000100
@SKIP1:
	sta S_CHECK_COLLISION::tmp1

	lda S_CHECK_COLLISION::tmp_posX
	and #%00001111
	beq @SKIP2

	inx
	jsr S_GET_BLOCK
	jsr S_IS_COLLISIONBLOCK
	beq @SKIP3
	lda S_CHECK_COLLISION::tmp_posX
	and #%00001111
	cmp #$09
	bpl @DOWN
	lda #%00000010
@SKIP3:
	ora S_CHECK_COLLISION::tmp1
	sta S_CHECK_COLLISION::tmp1

@SKIP2:
	lda S_CHECK_COLLISION::tmp1
	bne @COLLISION
	rts  ; -----------------------------
@COLLISION:
	cmp #%00000100
	beq @MOVE_RIGHT
	cmp #%00000010
	beq @MOVE_LEFT
@DOWN:
	ldx #$00
	stx ver_speed						; 上下スピード0 -> 自動で下降速度に変更
	inx
	stx is_collision_up
	rts  ; -----------------------------
@MOVE_RIGHT:
	lda S_CHECK_COLLISION::tmp_posX
	and #%11110000
	add #$10
	sub S_CHECK_COLLISION::move_amount_sum
	sta mario_pixel_speed
	lda #$01
	sta mario_x_direction
	rts  ; -----------------------------
@MOVE_LEFT:
	lda S_CHECK_COLLISION::tmp_posX
	and #%11110000
	sub S_CHECK_COLLISION::move_amount_sum
	cnn
	sta mario_pixel_speed
	lda #$00
	sta mario_x_direction
	; jsr S_FIX_OVER_L
	rts  ; -----------------------------


; ------------------------------------------------------------------------------
; 座標からブロックを取得、当たり判定のあるブロックかチェック
; 衝突してたらその位置を返す
; 引数：XレジスタにX座標、YレジスタにY座標
; Aレジスタ破壊
; 戻り値なし
; ------------------------------------------------------------------------------

S_GET_ISCOLLISION:
	jsr S_GET_BLOCK
	sta S_GET_ISCOLLISION::blockid
	jsr S_IS_COLLISIONBLOCK
	; 当たり判定のあるブロックが存在したときにマリオに対してどの位置にあるか返す
	bne @COLLISION
	rts  ; -----------------------------
@COLLISION:
	lda S_CHECK_COLLISION::tmp_posX
	and #%00001111
	cmp #$09
	bmi @COLLISION_EDGE
	cmp #$0a
	bpl @COLLISION_EDGE
	lda #%00000010						; 05~0bH
	rts  ; -----------------------------
@COLLISION_EDGE:						; 00~04, 0c~0fH
	lda #%00000101
	rts  ; -----------------------------


; ------------------------------------------------------------------------------
; 座標からブロックを拾ってくる
; 引数：XレジスタにX座標、YレジスタにY座標
; A、Yレジスタ破壊
; 戻り値：ブロック番号
; ------------------------------------------------------------------------------

S_GET_BLOCK:
	sty S_CHECK_COLLISION::tmp2
	txa
	add #$f0
	lda move_amount_disp
	adc #$00
	and #$01
	add #$04
	sta addr_upper
	tya
	asl
	asl
	asl
	asl
	sta tmp1
	txa
	and #%00001111
	ora tmp1
	sta addr_lower
	ldy #$00
	lda (addr_lower), y
	ldy S_CHECK_COLLISION::tmp2
	rts  ; -----------------------------


; ------------------------------------------------------------------------------
; ブロックに当たり判定があるか返す
; 引数：ブロック番号
; 破壊なし
; 戻り値：当たり判定があるとき1を、ないとき0を返す
; ------------------------------------------------------------------------------

S_IS_COLLISIONBLOCK:
	cmp #$00
	bne @SKIP1
	lda #$00
	rts  ; -----------------------------
@SKIP1:
	lda #$01
	rts  ; -----------------------------


; ------------------------------------------------------------------------------
; マリオの座標を取得してX, Yレジスタに格納、仮座標やブロック座標
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
	ldx mario_x_direction				; 分岐用
	bne @R
	sub mario_pixel_speed
	sta S_CHECK_COLLISION::move_amount_sum
	bcs @SKIP_INC_DISP
	ldx move_amount_disp
	dex
	stx S_CHECK_COLLISION::move_amount_disp
	jmp @SKIP_INC_DISP
@R:
	add mario_pixel_speed
	sta S_CHECK_COLLISION::move_amount_sum
	bcc @SKIP_INC_DISP
@INC_DISP:
	ldx move_amount_disp
	inx
	stx S_CHECK_COLLISION::move_amount_disp
@SKIP_INC_DISP:
	pha
	and #%00001111
	sta mario_posx_pixel
	pla
	rshift4
	sta mario_posx_block

	lda mario_pixel_speed
	ldx mario_x_direction
	bne @SKIP_CNN
	cnn
@SKIP_CNN:
	add move_amount_sum
	tax
	sta S_CHECK_COLLISION::tmp_posX
	rshift4
	sta S_CHECK_COLLISION::tmp_block_posX

	lda mario_posy
	add ver_speed
	; add ver_pos_fix_val
	tay
	sta S_CHECK_COLLISION::tmp_posY
	rshift4
	sta S_CHECK_COLLISION::tmp_block_posY

	rts  ; -----------------------------


; ------------------------------------------------------------------------------
; 左もしくは右にブロックがあるかチェック
; 引数：Aレジスタに左右方向（左:0、右:0）
; A、X、Yレジスタ破壊
; 戻り値：ゼロフラグが衝突なしで0、衝突で1
; ------------------------------------------------------------------------------

S_CHECK_ISBLOCK_LR:
	add S_CHECK_COLLISION::tmp_block_posX
	tax
	ldy S_CHECK_COLLISION::tmp_block_posY
	jsr S_GET_ISCOLLISION
	beq @SKIP1
	rts  ; -----------------------------	; 衝突
@SKIP1:
	lda S_CHECK_COLLISION::tmp_posY
	and #%00001111
	bne @SKIP2
	rts  ; -----------------------------	; 衝突なし、マリオの真横のみ確認
@SKIP2:
	iny
	jsr S_GET_ISCOLLISION
	rts  ; -----------------------------


; ------------------------------------------------------------------------------
; X座標の合計移動量などを取得する
; あたり判定前（あたり判定処理に使用）、あたり判定後（最終的なスピードを使う）に実行する
; 引数：Yレジスタ=0で合計移動量を保存せず、mario_posx_blockだけ変更
; Aレジスタ破壊
; 戻り値無し
; ------------------------------------------------------------------------------


S_STORE_AMOUNT_X:
	;jsr S_GET_MOVE_AMOUNT_X
	jsr S_GET_TMP_POS
	lda S_CHECK_COLLISION::move_amount_sum
	sta move_amount_sum
	lda S_CHECK_COLLISION::move_amount_disp
	sta move_amount_disp
	rts  ; -----------------------------