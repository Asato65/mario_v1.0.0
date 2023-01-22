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
.endscope

S_CHECK_COLLISION:
	jsr S_GET_MOVE_AMOUNT_X
	jsr S_GET_TMP_POS
	jsr S_CHECK_X_COLLISION
	lda mario_x_direction
	bne @CHECK_ISJUMP
	lda mario_posx						; 左向き
	sub mario_pixel_speed
	bpl @CHECK_ISJUMP
	lda #$01
	sta mario_x_direction
	lda mario_posx						; 左端を越えた時、位置を左端で固定
	sta mario_pixel_speed				; X座標(1F前)-左端 = X座標-0 = X座標 をスピードにする
	jsr S_GET_MOVE_AMOUNT_X
	lda S_CHECK_COLLISION::move_amount_sum
	sta move_amount_sum
	lda S_CHECK_COLLISION::move_amount_disp
	sta move_amount_disp
	rts  ; -----------------------------
@CHECK_ISJUMP:
	lda mario_isjump
	beq @CHECK_GROUND
	jsr S_CHECK_ISBLOCK
	lda ver_speed
	add ver_pos_fix_val
	add mario_posy
	sta mario_posy

	jsr S_GET_MOVE_AMOUNT_X
	lda S_CHECK_COLLISION::move_amount_sum
	sta move_amount_sum
	lda S_CHECK_COLLISION::move_amount_disp
	sta move_amount_disp
	rts  ; -----------------------------
@CHECK_GROUND:
	ldx S_CHECK_COLLISION::tmp_block_posX
	ldy S_CHECK_COLLISION::tmp_block_posY
	iny
	cpy #$0f
	bpl @SKIP1
	jsr S_GET_ISCOLLISION
	bne @SKIP2
	lda S_CHECK_COLLISION::tmp_posX
	and #%00001111
	beq @SKIP1
	inx
	jsr S_GET_ISCOLLISION
	beq @SKIP1
@SKIP2:
	lda S_CHECK_COLLISION::tmp_posY
	and #%11110000
	; add #$10
	; sub S_CHECK_COLLISION::tmp_posY
	; cnn
	; add mario_posy
	sta mario_posy
	ldx #$00
	lda VER_FORCE_DECIMAL_PART_DATA, X
	sta ver_force_decimal_part
	lda VER_FALL_FORCE_DATA
	sta ver_force_fall
	stx ver_speed_decimal_part
	stx ver_speed
	stx mario_isfly
	jsr S_GET_MOVE_AMOUNT_X
	lda S_CHECK_COLLISION::move_amount_sum
	sta move_amount_sum
	lda S_CHECK_COLLISION::move_amount_disp
	sta move_amount_disp
	rts  ; -----------------------------
@SKIP1:
	lda ver_speed
	add ver_pos_fix_val
	add mario_posy
	sta mario_posy

	jsr S_GET_MOVE_AMOUNT_X
	lda S_CHECK_COLLISION::move_amount_sum
	sta move_amount_sum
	lda S_CHECK_COLLISION::move_amount_disp
	sta move_amount_disp
	rts  ; -----------------------------


; ------------------------------------------------------------------------------
; X方向の当たり判定
; ブロックの存在チェック、座標ずらしまで
; ------------------------------------------------------------------------------

S_CHECK_X_COLLISION:
	lda mario_x_direction
	bne @R
	; L
	lda S_CHECK_COLLISION::tmp_posX
	and #%00001111
	cmp #$0c
	bpl @SKIP1
	rts  ; -----------------------------
@SKIP1:									; 0CH~(0FH)なら
	lda #$00							; mario_x_direction（引数に利用）
	jsr S_CHECK_ISBLOCK_LR
	beq @END_L
	lda S_CHECK_COLLISION::tmp_posX
	and #%11110000
	add #$10
	sub S_CHECK_COLLISION::tmp_posX
	sta mario_pixel_speed
	lda #$01
	sta mario_x_direction				; 左に移動中でぶつかったので右に移動
@END_L:
	rts  ; -----------------------------
@R:
	lda S_CHECK_COLLISION::tmp_posX
	and #%00001111
	bne @SKIP2
	rts  ; -----------------------------
@SKIP2:
	cmp #$05
	bmi @SKIP3
	rts  ; -----------------------------
@SKIP3:									; (01H)~04Hなら
	lda #$01
	jsr S_CHECK_ISBLOCK_LR
	beq @END_R
	lda move_amount_sum
	and #%00001111
	bne @SKIP4
	lda #$00
	sta mario_pixel_speed
	rts  ; -----------------------------
@SKIP4:
	lda move_amount_sum
	and #%11110000
	add #$10
	sub move_amount_sum
	sta mario_pixel_speed
	;lda #$00
	;sta mario_x_direction
@END_R:
	rts  ; -----------------------------


; ------------------------------------------------------------------------------
; ジャンプ時の左右ずらしや頭ぶつけるところまで
; 引数なし
; A、X、Yレジスタ破壊
; 戻り値なし
; ------------------------------------------------------------------------------

S_CHECK_ISBLOCK:
	ldx S_CHECK_COLLISION::tmp_block_posX
	ldy S_CHECK_COLLISION::tmp_block_posY
	jsr S_GET_ISCOLLISION
	and #%00000011
	asl
	asl
	sta S_CHECK_COLLISION::tmp1

	lda S_CHECK_COLLISION::tmp_posX
	and #%00001111
	beq @SKIP1

	inx
	jsr S_GET_ISCOLLISION
	and #%00000110
	lsr
	ora S_CHECK_COLLISION::tmp1
	sta S_CHECK_COLLISION::tmp1
@SKIP1:
	lda S_CHECK_COLLISION::tmp1
	bne @COLLISION
	rts  ; -----------------------------
@COLLISION:
	cmp #%00000100
	beq @MOVE_RIGHT
	cmp #%00000010
	beq @MOVE_LEFT
	lda #$00
	sta ver_speed						; 上下スピード0 -> 自動で下降速度に変更
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
	rts  ; -----------------------------


; ------------------------------------------------------------------------------
; 座標からブロックを取得して
; 引数：XレジスタにX座標、YレジスタにY座標
; Aレジスタ破壊
; 戻り値なし
; ------------------------------------------------------------------------------

.scope S_GET_ISCOLLISION
	blockid = $d6
.endscope

S_GET_ISCOLLISION:
	jsr S_GET_BLOCK
	sta S_GET_ISCOLLISION::blockid
	jsr S_IS_COLLISIONBLOCK
	; 当たり判定のあるブロックが存在したときにマリオに対してどの位置にあるか返す
	bne @SKIP1
	rts  ; -----------------------------
@SKIP1:
	lda S_CHECK_COLLISION::tmp_posX
	and #%00001111
	cmp #$05
	bmi @SKIP2
	cmp #$0c
	bpl @SKIP2
	lda #%00000010						; 05~0bH
	rts  ; -----------------------------
@SKIP2:									; 00~04, 0c~0fH
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
	lda mario_pixel_speed
	ldx mario_x_direction
	bne @SKIP1
	cnn
@SKIP1:
	add S_CHECK_COLLISION::move_amount_sum
	tax
	sta S_CHECK_COLLISION::tmp_posX
	lsr
	lsr
	lsr
	lsr
	sta S_CHECK_COLLISION::tmp_block_posX

	lda mario_posy
	add ver_speed
	tay
	sta S_CHECK_COLLISION::tmp_posY
	lsr
	lsr
	lsr
	lsr
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

S_GET_MOVE_AMOUNT_X:
	lda move_amount_sum
	ldx mario_x_direction				; 分岐用
	bne @R
	sub mario_pixel_speed
	sta S_CHECK_COLLISION::move_amount_sum
	bcs @SKIP_INC_DISP
	bcc @INC_DISP
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
	and #%11110000
	lsr
	lsr
	lsr
	lsr
	sta mario_posx_block

	rts  ; -----------------------------