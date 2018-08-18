scope world {
	scope Init: {
		lda #$00; ldx #$0028; ldy #$0060;
		jsl area.Load;
		
		lda #$09; sta video.screenmode;
		lda #$0f; sta video.brightness;
		
		ldx #$0000;
		stx video.scrollL1ColDest; stx video.scrollL1RowDest;
		stx video.scrollL2ColDest; stx video.scrollL2RowDest;
		stx video.scrollL3ColDest; stx video.scrollL3ColDest;
		
		ldx #cres.ids.shadow;
		ldy #>video.playerGfx; lda #<(video.playerGfx>>16);
		jsl decomp.DecompFile;
		
		ldx #>(video.playerGfx)>>1;
		stx >dynamo.gfxPtrs+cres.ids.shadow*2;
		
		ldx #cres.ids.orin_walking;
		ldy #>video.playerGfx+$40; lda #<(video.playerGfx>>16);
		jsl decomp.DecompFile;
		
		ldx #>(video.playerGfx+$40)>>1;
		stx >dynamo.gfxPtrs+cres.ids.orin_walking*2;
		
		inc >cmain.gameMode;
		// falls through to Main
	}
	
	scope Main: {
		inc >cmain.frame; inc >cmain.clock;
		jsl video.clearObj;
		
		jsl area.UpdateSprites;
		jsl sprite.Run;
		
		jsl area.Scroll;
		jsl dynamo.Draw;
		
		rtl;
	}
}