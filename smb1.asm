.setcpu "6502"
.feature c_comments
.autoimport on

.include "./inc/const_val.inc"			; 定数定義
.include "./inc/const_addr.inc"			; 変数名定義
.include "./inc/map.inc"				; マップデータ
.include "./inc/plt_data.inc"			; パレットデータ
.include "./inc/text_data.inc"			; 文字データ
.include "./inc/sound.inc"				; 音データ

.include "./asm/macro.asm"				; マクロ
.include "./asm/main.asm"				; メインルーチン
.include "./asm/sub.asm"				; その他サブルーチン
.include "./asm/move_chr.asm"			; マリオ移動
.include "./asm/move_chr_x.asm"			; マリオX方向移動
.include "./asm/move_chr_y.asm"			; マリオY方向移動
.include "./asm/collision.asm"			; マリオあたり判定
.include "./asm/anime.asm"				; マリオアニメーション
.include "./asm/nmi.asm"				; NMI
.include "./asm/draw_map.asm"			; マップ描画
.include "./asm/status.asm"				; ステータス表示
.include "./asm/sound.asm"				; 効果音


.segment "HEADER"
		.byte $4e, $45, $53, $1a
		.byte $02	; プログラムバンク
		.byte $01	; キャラクターバンク
		.byte $01	; 垂直ミラー
		.byte $00
		.byte $00, $00, $00, $00
		.byte $00, $00, $00, $00

.segment "STARTUP"
.proc RESET
		; IRQ初期化
		sei								; IRQ禁止
		cld								; BCD禁止

		; NesDevではAPUのフレームIRQを無効にしているが，特定のマッパーでのみ有効
		ldx #$ff
		txs
		inx
		stx $2000						; NMI無効化
		stx $2001						; 描画停止
		stx $4010						; APU DMCのIRQ（bit7）無効化

		/*
		A & $2002の結果でZ（ゼロフラグ）設定
		$2002のbit7 -> N（ネガティブフラグ）, bit6 -> V（オーバーフロー）に入る
		$2002のbit7にはVblank，bit6は0爆弾の状態が入っている
		リセット後のこのフラグは，状態が不定なので，一回bit命令でリセットが出来るらしい
		*/
		bit $2002

		; Vblank待機1回目
@VBLANK_WAIT1:
		bit $2002
		bpl @VBLANK_WAIT1

		; PPUが安定するまで約30,000サイクルの時間がある -> この間にRAMリセット

		txa									; X = 0

		; RAM初期化
		inirm $00, #$00
		inirm $0100, #$00
		inirm $0200, #$00
		inirm $0300, #$ff
		inirm $0400, #$00
		inirm $0500, #$00
		inirm $0600, #$00
		inirm $0700, #$00

		jsr S_INIT_SOUND

		; 値の設定
		lda #$28						; マリオのX座標（これはステージ読み込みを実装したとき移動させる）
		sta mario_posx
		sta move_amount_sum

		lda #$c0						; マリオのY座標
		sta mario_posy
		jsr S_RESET_PARAM_JUMP

		; マリオの方向
		lda #$01
		sta mario_x_direction
		sta mario_face_direction
		sta ver_speed

		; Vblank待機2回目
@VBLANK_WAIT2:
		bit $2002
		bpl @VBLANK_WAIT2

	ldx #$00
	ldy #$00
:
	dex
	bne :-
	dey
	bne :-

	lda #%00010000						; |NMI-OFF|PPU=MASTER|SPR8*8|BG$1000|SPR$0000|VRAM+1|SCREEN$2000|
	sta PPU_SET1
	lda #%00000110						; |R|G|B|DISP-SPR|DISP-BG|SHOW-L8-SPR|SHOW-L8-BG|MODE=COLOR|
	sta PPU_SET2

		inivrm #$00

		; パレットテーブルの転送
		lda #$3f
		sta PPU_ADDRESS
		lda #$00
		sta PPU_ADDRESS
		lda #$0f
		sta PPU_ACCESS

		; ステータスの表示
		; 不透明キャラクター配置（ゼロスプライト用）
		lda #$20
		sta PPU_ADDRESS
		lda #$60
		sta PPU_ADDRESS
		lda #$ff
		sta PPU_ACCESS

		; "TIME" キャラクター表示
		ldx #$00
		lda STATUS_STR_TIME, x
		sta PPU_ADDRESS
		inx
		lda STATUS_STR_TIME, x
		sta PPU_ADDRESS
		inx
@STORE_STATUS_TIME:
		lda STATUS_STR_TIME, x
		sta PPU_ACCESS
		inx
		cpx #$04+2
		bne @STORE_STATUS_TIME

		; タイマーセット
		lda #$04
		sta game_timer_bcd1
		lda #$00
		sta game_timer_bcd2
		sta game_timer_bcd3
		lda #$01
		sta timer_update_flag

.scope START
	counter = $d2
.endscope

		; マップの描画
		lda #$18
		sta START::counter
@STORE_MAP_INIT:
		jsr S_DRAW_ADDMAP				; マップを一列更新
		jsr S_TRANSFAR_OBJDATA_TOBUFFER
		jsr S_TRANSFAR_PLT_TOBUFFER
		jsr S_STORE_MAPOBJ_VRAM			; NMIで行っている作業
		jsr S_STORE_PLT_TO_BUFF
		dec START::counter
		bne @STORE_MAP_INIT

		; 0番スプライト
		lda #$00
		sta CHR_BUFFER::SPR0_POSX
		lda #$17
		sta CHR_BUFFER::SPR0_POSY
		lda #$ff
		sta CHR_BUFFER::SPR0_CHIP
		lda #%00000000					; 垂直|水平|優先度下げる|3bit無効|パレット2bit
		sta CHR_BUFFER::SPR0_ATTR

		lda #0
		sta $2003
		lda #$03	; SPR転送
		sta PPU_DMA

		; パレットテーブルの転送
		lda #$3f
		sta PPU_ADDRESS
		lda #$00
		sta PPU_ADDRESS
		ldx #$00
@STORE_PAL:
		lda INITIAL_PLT, x
		sta PPU_ACCESS
		inx
		cpx #$20
		bne @STORE_PAL

		; スクリーンON
		lda #%10001000	; NMI-ON, SPR=$1000
		sta PPU_SET1
		lda #%00011110	; すべて表示
		sta PPU_SET2

		lda #$00
		sta PPU_SCROLL
		sta PPU_SCROLL

		jmp MAINLOOP
.endproc

.proc MAINLOOP
		; メイン動作が終わっていれば（=1なら）
		; ループを回してNMI待ち
		lda isend_main
		bne MAINLOOP
		jsr S_MAIN	; メインルーチン

		jmp MAINLOOP
.endproc


.proc NMI
		pha
		; inc nmi_counter
		; メイン処理が終わっていれば（=1）NMIのメイン処理を実行
		lda isend_main
		bne @START_DRAW_DISP
		pla
		rti
@START_DRAW_DISP:
		txa
		pha
		tya
		pha
		inc frame_counter
		; オブジェクト，属性テーブル，スプライト転送
		lda frame_counter				; 偶数：オブジェクト、奇数：パレット
		and #%00000001
		bne @STORE_PLT
		jsr S_STORE_MAPOBJ_VRAM
		beq @SKIP_STORE_PLT
@STORE_PLT:
		jsr S_STORE_PLT_TO_BUFF
@SKIP_STORE_PLT:
		lda timer_update_flag
		beq @SKIP_UPDATE_TIME
		jsr S_DISP_TIME
		lda #$00
		sta timer_update_flag
@SKIP_UPDATE_TIME:
		lda #$03						; SPR転送
		sta PPU_DMA
		jsr S_SET_SCROLL				; スクロールレジスタ設定
		sta isend_main					; フラグリセット
@WAIT_END_VBLANK:						; VBlank終了待ち
		bit PPU_STATUS
		bvs @WAIT_END_VBLANK

		pla
		tay
		pla
		tax
		pla
		rti
.endproc


.proc IRQ
		rti
.endproc


.segment "CHARS"
		.incbin "bg-spr.chr"

.segment "VECTORS"
		.word NMI
		.word RESET
		.word IRQ