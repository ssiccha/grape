      PROGRAM ENUM
C
C COSET ENUMERATION USING LOOKAHEAD.
C VERSION 2.1, FORTRAN 77, JUST ONE STORAGE ARRAY  MEM.
C PROGRAM OUTPUT IS FOR coladjgt.c INPUT.
C COPYRIGHT L.H.SOICHER, 1992.
C
      IMPLICIT INTEGER(A-Z)
      PARAMETER(MAXMEM=4000000)
      COMMON MEM(MAXMEM)
C
C MAIN PROGRAM READS IN THE DATA AND CALLS SUBROUTINE ENUMGO TO DO 
C ALL THE WORK.
C
      OPEN(UNIT=1,FILE="GRAPE_tcin")
      OPEN(UNIT=2,FILE="GRAPE_tcout")
      REWIND(1)
      REWIND(2)
      READ(1,*)ILOOKA,OUTSW,NSTOP,MAXC
C READ IN INVERSES OF GENERATORS, SUBGROUP GENERATORS, AND RELATORS.
C STREL IS THE POINT IN  MEM  WHERE THE RELATORS BEGIN (AFTER THE
C SUBGROUP GENERATORS).
C ILOOKA IS THE INDEX INCREMENT AT WHICH LOOKAHEAD TAKES PLACE.
C IF ILOOKA=0 THEN LOOKAHEAD TAKES PLACE EVERY TIME THE INDEX DOUBLES.
C OUTSW=1 IFF OUTPUT OF THE COSET TABLE IS REQUIRED.
C THE ENUMERATION FAILS IF END OF TABLE IS REACHED  NSTOP  TIMES.
C MAXC  IS THE MAXIMUM NUMBER OF LIVE COSETS.
      READ(1,*)NGEN
      IF(NGEN.LE.0)THEN
         WRITE(2,*)' NO GENERATORS - TRIVIAL GROUP'
	 CALL ERSTOP
      ENDIF
      IF(NGEN.GT.MAXMEM)THEN
         WRITE(2,*)' ERROR - MAXMEM TOO SMALL'
         CALL ERSTOP
      ENDIF
      READ(1,*)(MEM(J),J=1,NGEN)
      L=NGEN+1
    3 READ(1,*)LENGTH
      IF(LENGTH.EQ.0)GOTO 3
      IF(LENGTH.EQ.-2)LENGTH=0
      IF(LENGTH.GE.0)GOTO 4
      STREL=L
      GOTO 3
    4 IF(L+LENGTH.GT.MAXMEM)THEN
         WRITE(2,*)' ERROR - MAXMEM TOO SMALL'
         CALL ERSTOP
      ENDIF
      MEM(L)=LENGTH
      IF(LENGTH.EQ.0)GOTO 2
      FRONT=L+1
      BACK=L+LENGTH
      READ(1,*)(MEM(J),J=FRONT,BACK)
      L=BACK+1
      GOTO 3
    2 IF(MAXC.EQ.0)MAXC=(MAXMEM-L)/(NGEN+2)
      IF(MAXC.LT.2)THEN
         WRITE(2,*)' ERROR - MAXC TOO SMALL'
	 CALL ERSTOP
      ENDIF
      IF(L+(NGEN+2)*MAXC.GT.MAXMEM)THEN
	  WRITE(2,*)' ERROR - MAXMEM TOO SMALL'
	  CALL ERSTOP
      ENDIF
      CALL ENUMGO(MEM(1),MEM(1+NGEN),MEM(L+1),MEM(L+MAXC+1),
     1            MEM(L+2*MAXC+1),
     1            NGEN,L-NGEN,STREL-NGEN,MAXC,ILOOKA,OUTSW,NSTOP)
      STOP
      END
      SUBROUTINE ENUMGO(INV,W,ULINK,DLINK,T,
     1                  NGEN,WLEN,STREL,MAXC,ILOOKA,OUTSW,NSTOP)
      IMPLICIT INTEGER(A-Z)
      LOGICAL LOOKA,CLOSED
      INTEGER INV(NGEN),W(WLEN),ULINK(MAXC),DLINK(MAXC),T(NGEN,MAXC)
C
C MAIN SUBROUTINE TO DO COSET ENUMERATION.
C
C FIRST, INITIALIZE ACTIVE COSET LIST, FREELIST, AND COINCIDENCE QUEUE.
C IF  Y  IS IN THE COINCIDENCE QUEUE THEN  Y  IS COINCIDENT
C WITH  -ULINK(Y) (< Y).
C CURC IS THE CURRENT COSET BEING PROCESSED.
C CURW IS A POINTER TO THE CURRENT WORD CURC IS BEING PUSHED THROUGH.
C LASTCL IS THE LAST CLOSED COSET.
C LASTC IS THE LAST ACTIVE COSET.
C ASSUMES  MAXC.GE.2.
      ISTOP=0
      LASTC=1
      LASTCL=0
      CURC=1
      ULINK(1)=0
      DLINK(1)=0
      DO 5 J=1,NGEN
    5 T(J,1)=0
      CURW=1
      FREEL=2
      L=MAXC-1
      DO 6 J=2,L
    6 DLINK(J)=J+1
      DLINK(MAXC)=0
      FRONTQ=0
      BACKQ=0
      INDEX=1
      MAXDEF=1
      TOTDEF=1
      NLOOKA=ILOOKA+1
      IF(ILOOKA.EQ.0)NLOOKA=2
      LOOKA=.FALSE.
      CLOSED=.TRUE.
C MAIN LOOP.
   99 IF(LASTC.EQ.LASTCL)GOTO 88
      IF(CURC.NE.0)GOTO 7
C LOOKAHEAD FINISHED.
      IF(FREEL.EQ.0)GOTO 89
      LOOKA=.FALSE.
      CLOSED=.TRUE.
      NLOOKA=INDEX+ILOOKA
      IF(ILOOKA.EQ.0)NLOOKA=2*INDEX
      IF(LASTCL.EQ.0)GOTO 8
      CURC=DLINK(LASTCL)
      CURW=STREL
      GOTO 7
    8 CURC=1
      CURW=1
    7 LENGTH=W(CURW)
      FRONT=CURW+1
      BACK=CURW+LENGTH
      FRONTC=CURC
      BACKC=CURC
C FORWARD SCAN.
   12 NEXTC=T(W(FRONT),FRONTC)
      IF(NEXTC.EQ.0)GOTO 13
      FRONTC=NEXTC
      FRONT=FRONT+1
      IF(FRONT.GT.BACK)GOTO 14
      GOTO 12
C BACKWARD SCAN.
   13 NEXTC=T(INV(W(BACK)),BACKC)
      IF(NEXTC.EQ.0)GOTO 15
      BACKC=NEXTC
      BACK=BACK-1
      IF(FRONT.GT.BACK)GOTO 14
      GOTO 13
   15 IF(FRONT.EQ.BACK)GOTO 17
      IF(.NOT.LOOKA.AND.FREEL.NE.0.AND.INDEX.LT.NLOOKA)GOTO 9
      IF(LOOKA)GOTO 42
      IF(FREEL.NE.0)GOTO 43
C REACHED END OF TABLE.
      ISTOP=ISTOP+1
      IF(ISTOP.EQ.NSTOP)GOTO 89
   43 LOOKA=.TRUE.
   42 CLOSED=.FALSE.
      CURW=CURW+LENGTH+1
      IF(W(CURW).NE.0)GOTO 99
      CURC=DLINK(CURC)
      CURW=STREL
      CLOSED=.TRUE.
      GOTO 99
C DEFINE NEW COSET.
    9 INDEX=INDEX+1
      IF(INDEX.GT.MAXDEF)MAXDEF=INDEX
      TOTDEF=TOTDEF+1
      L=FREEL
      FREEL=DLINK(FREEL)
      CALL INSERT(L,LASTC,ULINK,DLINK,MAXC)
      LASTC=L
      DO 21 J=1,NGEN
   21 T(J,L)=0
      T(W(BACK),L)=BACKC
      T(INV(W(BACK)),BACKC)=L
      BACKC=L
      BACK=BACK-1
      GOTO 12
C DEDUCTION.
   17 T(W(FRONT),FRONTC)=BACKC
      T(INV(W(FRONT)),BACKC)=FRONTC
      FRONTC=BACKC
   14 CURW=CURW+LENGTH+1
      IF(W(CURW).NE.0)GOTO 20
      YY=CURC
      CURC=DLINK(CURC)
      CURW=STREL
C THE NEXT STATEMENT PREVENTS A COSET YY > 1 GOING BEFORE COSET 1
C ON THE ACTIVE COSET LIST.
      IF(YY.NE.1.AND.LASTCL.EQ.0)CLOSED=.FALSE.
      IF(.NOT.CLOSED.OR.ULINK(YY).EQ.LASTCL)GOTO 10
      IF(YY.EQ.LASTC)LASTC=ULINK(YY)
      CALL DELETE(YY,ULINK,DLINK,MAXC)
      CALL INSERT(YY,LASTCL,ULINK,DLINK,MAXC)
   10 IF(CLOSED)LASTCL=YY
      CLOSED=.TRUE.
   20 IF(FRONTC.EQ.BACKC)GOTO 99
C
C PROCESS COINCIDENCE.
      IF(FRONTC.LT.BACKC)THEN
      X=FRONTC
      Y=BACKC
      ELSE
      X=BACKC
      Y=FRONTC
      ENDIF
      INDEX=INDEX-1
      IF(Y.NE.CURC)GOTO 35
      CURC=DLINK(CURC)
      CURW=STREL
      CLOSED=.TRUE.
   35 IF(Y.EQ.LASTCL)LASTCL=ULINK(Y)
      IF(Y.EQ.LASTC)LASTC=ULINK(Y)
      CALL DELETE(Y,ULINK,DLINK,MAXC)
   23 DO 24 J=1,NGEN
      JX=T(J,X)
      IF(JX.EQ.Y)JX=X
      JY=T(J,Y)
      IF(JY.EQ.Y)JY=X
      IF(JX.EQ.0.OR.JY.EQ.0.OR.JX.EQ.JY)GOTO 24
C POSSIBLE NEW COINCIDENCE.
   30 IF(ULINK(JX).GE.0) GOTO 31
      JX=-ULINK(JX)
      GOTO 30
   31 IF(ULINK(JY).GE.0)GOTO 32
      JY=-ULINK(JY)
      GOTO 31
   32 IF(JX.EQ.JY)GOTO 24
      IF(JX.GT.JY)THEN
      TEMP=JX
      JX=JY
      JY=TEMP
      ENDIF
      INDEX=INDEX-1
      IF(JY.NE.CURC)GOTO 36
      CURC=DLINK(CURC)
      CURW=STREL
      CLOSED=.TRUE.
   36 IF(JY.EQ.LASTCL)LASTCL=ULINK(JY)
      IF(JY.EQ.LASTC)LASTC=ULINK(JY)
      CALL DELETE(JY,ULINK,DLINK,MAXC)
      IF(BACKQ.EQ.0)FRONTQ=JY
      ULINK(JY)=-JX
      DLINK(JY)=0
      IF(BACKQ.NE.0)DLINK(BACKQ)=JY
      BACKQ=JY
   24 CONTINUE
C UPDATE TABLE.
      DO 25 J=1,NGEN
      JY=T(J,Y)
      IF(JY.EQ.0)GOTO 25
      IF(JY.EQ.Y)T(J,Y)=X
      IF(JY.NE.Y)T(INV(J),JY)=0
   25 CONTINUE
      DO 26 J=1,NGEN
      JX=T(J,X)
      JY=T(J,Y)
      IF(JX.NE.0.OR.JY.EQ.0)GOTO 26
      IF(JY.EQ.X.AND.T(INV(J),X).NE.0)GOTO 26
      T(J,X)=JY
      T(INV(J),JY)=X
   26 CONTINUE
C RETURN Y TO THE FREELIST.
      DLINK(Y)=FREEL
      FREEL=Y
      IF(FRONTQ.EQ.0)GOTO 99
C OBTAIN NEXT COINCIDENCE TO PROCESS.
      Y=FRONTQ
      FRONTQ=DLINK(Y)
      IF(FRONTQ.EQ.0)BACKQ=0
      X=-ULINK(Y)
      GOTO 23
C
C WRITE RESULT.
   88 WRITE(2,102)INDEX
  102 FORMAT(' INDEX = ',I8)
      WRITE(2,103)MAXDEF
  103 FORMAT(' MAX.  NO. OF COSETS DEFINED = ',I8)
      WRITE(2,104)TOTDEF
  104 FORMAT(' TOTAL NO. OF COSETS DEFINED = ',I8)
      GOTO 999
   89 WRITE(2,105)MAXC
  105 FORMAT(' RUN OUT OF SPACE AFTER ',I8,' COSETS.')
      WRITE(2,104)TOTDEF
  999 CLOSE(1)
      CLOSE(2)
C ULINK MAY BE CHANGED BY THE FOLLOWING CALL TO PGEN.
      CALL PGEN(T,ULINK,DLINK,NGEN,INV,LASTCL,OUTSW,MAXC,W,STREL)
      RETURN
      END
      SUBROUTINE DELETE(Y,ULINK,DLINK,MAXC)
C DELETES  Y  FROM THE ACTIVE COSET LIST.
C WE ASSUME  ULINK(Y).NE.0.
      IMPLICIT INTEGER(A-Z)
      DIMENSION ULINK(MAXC),DLINK(MAXC)
      IF(DLINK(Y).NE.0)ULINK(DLINK(Y))=ULINK(Y)
      DLINK(ULINK(Y))=DLINK(Y)
      RETURN
      END
      SUBROUTINE INSERT(Y,Z,ULINK,DLINK,MAXC)
C INSERTS  Y  AFTER  Z  IN THE ACTIVE COSET LIST.
C WE ASSUME  Z.NE.0.
      IMPLICIT INTEGER(A-Z)
      DIMENSION ULINK(MAXC),DLINK(MAXC)
      IF(DLINK(Z).NE.0)ULINK(DLINK(Z))=Y
      DLINK(Y)=DLINK(Z)
      ULINK(Y)=Z
      DLINK(Z)=Y
      RETURN
      END
      SUBROUTINE PGEN(T,MAP,DLINK,NGEN,INV,LASTCL,OUTSW,MAXC,
     1                W,STREL)
C IF THE ENUMERATION WAS SUCCESSFUL AND OUTSW.NE.0, OUTPUTS 
C PERMUTATIONS FROM COSET TABLE AS WELL AS WORDS FOR GENERATOR
C INVERSES AND SUBGROUP GENERATORS.
C THE OUTPUT (ON STDOUT) IS IN  CA  FORMAT.
      IMPLICIT INTEGER(A-Z)
      DIMENSION T(NGEN,MAXC),MAP(MAXC),DLINK(MAXC),INV(NGEN),
     1          W(STREL)
      IF(DLINK(LASTCL).NE.0.OR.OUTSW.EQ.0)THEN
         WRITE(*,103)0
	 RETURN
      ENDIF
      N=0
      K=1
    1 N=N+1
      MAP(K)=N
      K=DLINK(K)
      IF(K.NE.0)GOTO 1
      WRITE(*,103)NGEN
  103 FORMAT(I8)
      DO 2 J=1,NGEN
      WRITE(*,103)N
      K=1
    3 WRITE(*,103)MAP(T(J,K))
      K=DLINK(K)
      IF(K.NE.0)GOTO 3
    2 CONTINUE
      WRITE(*,103)NGEN
      DO 6 J=1,NGEN
      WRITE(*,103)1
      WRITE(*,103)INV(J)
    6 CONTINUE
      WCNT=0
      J=1
   10 IF(J.EQ.STREL)GOTO 9
      WCNT=WCNT+1
      J=J+W(J)+1
      GOTO 10
    9 WRITE(*,103)WCNT   
      DO 8 J=1,STREL-1
    8 WRITE(*,103)W(J)     
      RETURN
      END
      SUBROUTINE ERSTOP
      CLOSE(1)
      CLOSE(2)
      WRITE(*,103)0
  103 FORMAT(I8)
      STOP
      END
