;***********************************************
;   CLOCK       8MHz(内部クロック)
;   PORTB       0;LED赤
;
;   LEDを点滅させる(TMR0使用)
;***********************************************

    ;***********************************************
    ;   使用するPICとインクルード設定
    ;***********************************************
    LIST  P=16F88
    #INCLUDE "p16f88.inc"

;***********************************************
;   コンフィギュレーション設定
;***********************************************
; CONFIG1
; __config 0xEF70
    __CONFIG _CONFIG1, _INTRC_IO & _WDT_OFF & _PWRTE_ON & _MCLRE_OFF & _BOREN_ON & _LVP_OFF & _CPD_OFF & _WRT_OFF & _CPD_OFF

; CONFIG2
; __config 0xFFFC
    __CONFIG _CONFIG2, _FCMEN_OFF & _IESO_OFF

;***********************************************
;   定数定義
;***********************************************
tm0_cnt    EQU     H'20'    ; TMR0割り込み発生カウント
save_st    EQU     H'21'    ; STATUSのセーブ領域
save_w     EQU     H'22'    ; W-regのセーブ領域
 

    ORG     0               ; リセットベクタ(0番地)の指定
    GOTO    INIT            ; 初期処理に飛ぶ

    ;***********************************************
    ; 割り込み処理 TMR0使用
    ;***********************************************
    ORG     4               ; 割り込みベクタ(4番地)の指定
    BCF     INTCON,TMR0IF   ; TMR0オーバーフロー割り込みフラグリセット
    BSF	    INTCON,TMR0IE   ; TMR0割り込み許可
    MOVWF   save_w          ; W_regセーブ
    SWAPF   STATUS,W
    MOVWF   save_st         ; STATUSレジスタセーブ

    GOTO    ITR_MAIN

;***********************************************
;   初期化処理
;***********************************************
INIT
    BSF     STATUS,RP0
    
    MOVLW   70H             ; 内蔵クロックの周波数を8MHzに設定
    MOVWF   OSCCON	    ; 内蔵クロック設定
    
    CLRF    TRISB	    ; PORTB設定(すべて出力)

    MOVLW   H'87'           ; OPTIONレジスタの設定
    MOVWF   OPTION_REG      ; PORTBプルアップ使用しない、TMR0クロックソース(内部クロック)、プリスケーラー1/256

    BCF     STATUS,RP0      ; バンク0に切り替え

    MOVLW   D'19'           ; TMR0割り込み回数
    MOVWF   tm0_cnt         ; 割り込みカウンタ設定

    CLRF    PORTB           ; PORTBをクリア
    CLRF    TMR0            ; TMR0をクリア

　　MOVLW   H'A0'           ; INTCONレジスタ設定
    MOVWF   INTCON          ; 全体割り込み許可、タイマ0割り込み許可

;***********************************************
;   メインループ処理
;***********************************************
MAIN_LOOP
    NOP
    GOTO    MAIN_LOOP

;***********************************************
;   TMR0割り込みメイン処理
;***********************************************
ITR_MAIN
    DECFSZ  tm0_cnt,F       ; TMR0割り込み発生カウント回数完了したかの確認
    GOTO    TM0EXIT         ;	カウントしてなければTM0EXITへ

    MOVLW   H'01'
    XORWF   PORTB,F	    ; RB0反転
    
    MOVLW   D'19'	    ; 割り込みカウンタ回数を19
    MOVWF   tm0_cnt         ; 割り込みカウンタ設定

;***********************************************
;   TMR0割り込み終了処理
;***********************************************
TM0EXIT
    SWAPF   save_st,W
    MOVWF   STATUS          ; STATUSレジスタロード
    SWAPF   save_w,F
    SWAPF   save_w,W        ; W-regロード
    MOVLW   H'0' 
    MOVWF   TMR0	    ; TMR0クリア
    RETFIE		    ; 割り込み許可にしてリターン
    
    END
