      subroutine bonds() 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double  
      USE molkst_C, only : norbs, numat, nopen, fract, nclose, nelecs, nalpha, nbeta, keywrd
      use permanent_arrays, only : nfirst, nlast, nat, p, c, pa, pb
      USE parameters_C, only : tore
      USE chanel_C, only : iw
!***********************************************************************
!DECK MOPAC
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:47:36  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
!-----------------------------------------------
!   I n t e r f a c e   B l o c k s
!-----------------------------------------------
      use vecprt_I 
   !   use mpcbds_I 
      use dopen_I 
      implicit none
!-----------------------------------------------
!   G l o b a l   P a r a m e t e r s
!-----------------------------------------------
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!----------------------------------------------- 
      real(double)  :: b(norbs,norbs) 
      real(double)  :: bondab(5555)   
      real(double)  :: sdm(8765) 
      real(double)  :: aux(numat,numat) 
      real(double)  :: pspin(8765) 
      real(double)  :: spinab(555) 
!-----------------------------------------------
!   L o c a l   P a r a m e t e r s
!-----------------------------------------------
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer :: nopn, k, i, j, n, m, mu, l, ij, ll, kk, il, ih, &
        ilih 
      real(double), dimension(numat) :: spna, v, fv, sq, aq, tq, pm, sp, sd, &
        spsa, spsq 
      real(double) :: zkappa, sum, a, x, da, aa 
      logical :: ci, nci, kci 
!-----------------------------------------------
!
!*********************************************************************
!   CALCULATES AND PRINTS THE BOND INDICES AND VALENCIES OF ATOMS
!   FOR REFERENCE, SEE "BOND INDICES AND VALENCY", J.C.S.DALTON,
!   ARMSTRONG,D.R., PERKINS,P.G. AND STEWART,J.J.P., 838 (1973)
!
!  ON INPUT
!           P = DENSITY MATRIX, LOWER HALF TRIANGLE, PACKED.
!               P IS NOT ALTERED BY BONDS
!
!*********************************************************************
      
!
      ci = index(keywrd,'C.I.') + index(keywrd,'MECI') /= 0 
      kci = index(keywrd,'MICROS') == 0 
      nci = index(keywrd,'ROOT') + index(keywrd,'OPEN') == 0 
      nopn = nopen - nclose 
      nelecs = nclose + nclose + nopn 
!*****   CALCULATE THE DEGREE OF BONDING   ************
!
      k = 0 
      do i = 1, norbs 
        do j = 1, i 
          k = k + 1 
          b(i,j) = p(k) 
          b(j,i) = p(k) 
        end do 
      end do 
!
! *******  CALCULATE KAPPA FACTOR FOR UHF OR ROHF  ******************
!
      if (index(keywrd,'UHF') /= 0) then 
!****** UHF CASE
        zkappa = 0.D0 
        do n = 1, nalpha 
          do m = 1, nbeta 
            sum = 0.D0 
            do mu = 1, norbs 
              l = mu + norbs*(n - 1) 
              k = mu + norbs*(m - 1) 
       !       sum = sum + c(l)*cb(k) 
            end do 
            zkappa = zkappa + sum**2 
          end do 
        end do 
        zkappa = 1.D0/(zkappa/dble(nalpha + nbeta) + 0.5D0) 
      else 
        if (.not.ci .and. nopn==0 .and. nci .and. kci) then 
          zkappa = 1.D0 
        else 
!****** ROHF CASE
          zkappa = 1.D0/(1.D0 - (dble(nopn)/dble(nelecs))/2.D0) 
        endif 
      endif 
      ij = 0 
      do i = 1, numat 
        a = 0.0D00 
        l = nfirst(i) 
        ll = nlast(i) 
        do j = 1, i 
          ij = ij + 1 
          k = nfirst(j) 
          kk = nlast(j) 
          x = 0.0D0 
          do il = l, ll 
            do ih = k, kk 
              x = x + b(il,ih)*b(il,ih) 
            end do 
          end do 
          bondab(ij) = x 
        end do 
        x = -bondab(ij) 
        do j = l, ll 
          a = a + b(j,j) 
          x = x + 2.D0*b(j,j) 
        end do 
        v(i) = x 
        sd(i) = a 
      end do 
!
!
! ***** CALCULATE ACTIVE CHARGE (AQ), SELF CHARGE (SQ), FREE VALENCE(FV)
!        TOTAL CHARGE (TQ), MULLIKEN TYPE PROMOTION (PM) AND STATISTICAL
!          PROMOTION (SP)  ********************************************
!
      k = 0 
      do i = 1, numat 
        do j = 1, i 
          k = k + 1 
          bondab(k) = bondab(k)*zkappa 
          aux(i,j) = bondab(k) 
          aux(j,i) = bondab(k) 
        end do 
        bondab(k) = v(i) 
      end do 
      do i = 1, numat 
        da = 0.0D0 
        do j = 1, numat 
          if (j == i) cycle  
          da = da + aux(i,j) 
        end do 
        aq(i) = da 
        sq(i) = (aux(i,i)-da)/2.D00 
        fv(i) = v(i) - aq(i) 
        tq(i) = aq(i) + sq(i) 
        pm(i) = sd(i) - tore(nat(i)) 
        sp(i) = tq(i) - tore(nat(i)) 
      end do 
!
!
!  ********   OUTPUT    *****************
!
!
      write (iw, '(2/)') 
      write (iw, '(1X,2/20X,''BOND ORDERS AND VALENCIES'')') 
      call vecprt (bondab, numat) 
      if (index(keywrd,' LARGE') == 0) return  
      write (iw, '(3/)') 
      write (iw, '(A)') ' SELF-Q:    SELF OR INACTIVE CHARGE' 
      write (iw, '(A)') ' ACTIV-Q:   CHARGE WHICH IS USED TO FORM BONDS' 
      write (iw, '(A)') ' TOTAL-Q:   SELF-Q + ACTIV-Q' 
      write (iw, '(A)') ' FREE-VA:   TOTAL-Q - VALENCE' 
      write (iw, '(A)') ' STAT.PROM: TOTAL-Q - CORE CHARGE' 
      write (iw, '(A)') ' MULL.PROM: -CHARGE (SEE ABOVE)' 
      write (iw, &
      '(/,1X,5X,''SELF-Q'',4X,''ACTIV-Q'',3X,''TOTAL-Q'',3X,   ''VALENCE'',3X,'&
      &'FREE-VA'',1X,''STAT.PROM'',1X,''MULL.PROM'',2/)') 
      write (iw, '(1X,I2,7F10.5/)') (i,sq(i),aq(i),tq(i),v(i),fv(i),sp(i),pm(i)&
        ,i=1,numat) 
!****** PERFORM SPIN POPULATION STATISTICAL ANALYSIS
      if (index(keywrd,'UHF') == 0) then 
        if (.not.ci .and. nopn==0 .and. nci .and. kci) then 
          write (iw, '(1X,''CLOSED SHELL'',2/)') 
          return  
        else 
          call dopen (c, norbs, norbs, nclose, nopen, fract, sdm) 
          pspin = sdm 
!       WRITE(IW,'(1X,''SDM'',10E12.3)')(SDM(J),J=1,LINEAR)
          write (iw, '(1X,''ROHF'',2/)') 
          go to 160 
        endif 
      endif 
      write (iw, '(1X,''UHF '',2/)') 
      pspin = pa - pb 
      sum = 0.D0 
      l = 0 
      do i = 1, norbs 
        do j = 1, i 
          aa = 2.D0 
          if (i == j) aa = 1.D0 
          l = l + 1 
          sum = sum + aa*(pspin(l)*p(l)) 
        end do 
      end do 
      write (iw, '(2/)') 
      write (iw, '(10X,''NALPHA-NBETA= '',F10.5,2/)') sum 
  160 continue 
      write (iw, '(1X,''OPEN SHELL & UHF CASE'',2/)') 
!#      WRITE(IW,'(1X,10X,51(''* '')//1X,10X,''* '',9X,''STATISTICAL SPI
!#     + POPULATION ANALYSIS'',9X,''* '',//1X,10X,51(''* ''))')
! EVALUATE  THE CORRESPONDING INACTIVE ATOMIC AND BOND SPIN POPULATIONS
      ij = 0 
      do i = 1, numat 
        l = nfirst(i) 
        ll = nlast(i) 
        do j = 1, i 
          ij = ij + 1 
          k = nfirst(j) 
          kk = nlast(j) 
          x = 0.D0 
          do il = l, ll 
            do ih = k, kk 
              if (il >= ih) then 
                ilih = (il*(il - 1))/2 + ih 
              else 
                ilih = (ih*(ih - 1))/2 + ij 
              endif 
              x = x + b(il,ih)*pspin(ilih) 
            end do 
          end do 
          spinab(ij) = x 
        end do 
      end do 
! EVALUATE THE TOTAL ATOMIC SPIN POPULATIONS
      k = 0 
      do i = 1, numat 
        do j = 1, i 
          k = k + 1 
          aux(i,j) = spinab(k) 
          aux(j,i) = spinab(k) 
        end do 
      end do 
      do i = 1, numat 
        da = 0.D0 
        do j = 1, numat 
          if (j == i) cycle  
          da = da + aux(i,j) 
        end do 
        spsa(i) = da 
        spsq(i) = aux(i,i) 
        spna(i) = da + aux(i,i) 
      end do 
      write (iw, '(2/20X,''SELF UNPAIRED AND BOND SPIN POPULATIONS ''/)') 
      call vecprt (spinab, numat) 
      write (iw, '(2/)') 
      write (iw, '(10X,'' TOTAL ATOMIC SPIN POPULATIONS''/)') 
      write (iw, &
      '(1X,''ATOM    SELF UNCPLD SPIN    SHARED UNCPLD SPIN     TOTAL UNCPLD SP&
      &IN '',3/(1X,I3,3F20.5))') (i,spsq(i),spsa(i),spna(i),i=1,numat) 
      return  
      end subroutine bonds


      subroutine dopen(c, mdim, norbs, ndubl, nsingl, fract, sdm) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:47:36  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(in) :: mdim 
      integer , intent(in) :: norbs 
      integer , intent(in) :: ndubl 
      integer , intent(in) :: nsingl 
      real(double) , intent(in) :: fract 
      real(double) , intent(in) :: c(mdim,mdim) 
      real(double) , intent(out) :: sdm((mdim*(mdim + 1))/2) 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer :: nl1, nu1, l, i, j
      real(double) :: frac, sum1 
!-----------------------------------------------
!**********************************************************************
!
!  DOPEN COMPUTES THE DENSITY MATRIX OF OPEN SHELL ROHF STATE FUNCTIONS
!  FROM THE EIGENVECTOR MATRIX AND THE M.O'S OCCUPANCIES
!
!  INPUT:   C      = SQUARE EIGENVECTOR MATRIX C
!           NORBS  = NUMBER OF ORBITALS
!           NDUBL  = NUMBER OF DOUBLY OCCUPIED M.O'S (=0 IF UHF)
!           NSINGL = NUMBER OF SINGLY OR FRACTIONALLY OCCUPIED M.O'S
!
!  EXIT:    SDM    = ROHF OPEN SHELL DENSITY MATRIX
!
!**********************************************************************
!
!  SET UP LIMITS FOR SUMS
!    NL1 = BEGINNING OF ONE ELECTRON SUM
!    NU1 = END OF THE SAME
!
      frac = fract 
      nl1 = ndubl + 1 
      nu1 = nsingl 
      l = 0 
      do i = 1, norbs 
        do j = 1, i 
          l = l + 1 
          sum1 = 0.D0 
          sum1 = sum(c(i,nl1:nu1)*c(j,nl1:nu1)) 
          sdm(l) = sum1*frac 
        end do 
      end do 
      return  
      end subroutine dopen
