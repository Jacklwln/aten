      subroutine pmep() 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      use permanent_arrays, only : nat, geo, &
      & coord
      USE molkst_C, only : numat, keywrd, moperr, jobnam 
      USE chanel_C, only : iw
!***********************************************************************
!  THIS IS A DRIVING ROUTINE FOR COMPUTATIONS OF PMEP - PARAMETRIC
!  MOLECULAR ELECTROSTATIC POTENTIAL AS WELL AS  MEP CHARGES.
!
!  REF.  B. WANG AND G.P.FORD J.COMPT.CHEM. IN PRESS.
!        G.P.FORD AND B. WANG J.COMPT.CHEM. 14(1993)1101.
!
!                               WRITTEN BY BINGZE WANG, AUGUST 1993
!***********************************************************************
!***********************************************************************
!DECK MOPAC
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:03:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
!-----------------------------------------------
!   I n t e r f a c e   B l o c k s
!-----------------------------------------------
      use second_I 
      use gmetry_I 
      use mepmap_I 
      use grids_I 
      use surfa_I 
      use mepchg_I 
      implicit none
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer ::  is =0, nmep, i
      real(double), dimension(3,numat*50 + 1000) :: potpt 
      real(double), dimension(107) :: alpw 
      real(double) :: t1 
!----------------------------------------------- 
      data alpw/ 2.92D0, 4*0.0D0, 4.36D0, 6.95D0, 9.22D0, 5.53D0, 0.0D0, 4*&
        0.0D0, 2.3D0, 2.6D0, 3.32D0, 17*0.0D0, 3.32D0, 72*0.0D0/  
      data nmep/ 0/  
!                                                 CHECK FOR SAVING TIME
      if (index(keywrd,' AM1') /= 0) then 
        do i = 1, numat 
          if (alpw(nat(i)) < 0.1D0) go to 30 
        end do 
!
        t1 = second(1) 
!
        call gmetry (geo, coord) 
        if (moperr) return  
!                                              ***** CALCULATE MEP ONLY
        if (index(keywrd,' PMEP') /= 0) then 
          i = index(jobnam,' ') - 1 
          open(unit=is, file=jobnam(:i)//'.mep', status='UNKNOWN', position=&
            'asis') 
          call mepmap (coord) 
          if (moperr) return  
          go to 20 
        endif 
!                         ***** CHOOSE SURFACE WHERE POINTS ARE SAMPLED
!
        if (index(keywrd,'WILLIAMS') /= 0) then 
!                                                  THE WILLIAMS SURFACE
          call grids (coord, potpt, nmep) 
          if (moperr) return  
        else 
!                                                  THE CONNOLLY SURFACE
          call surfa (coord, potpt, nmep) 
          if (moperr) return  
        endif 
!                                           ***** CALCULATE MEP CHARGES
        call mepchg (coord, potpt, nmep) 
!
   20   continue 
        t1 = second(1) - t1 
        write (iw, '(/1X,A,F9.2,A)') 'TIME TO CALCULATE MEP', t1, ' SECONDS' 
        return  
      endif 
   30 continue 
      write (iw, *) ' AM1 PARAMETERS FOR H,C,N,F AND CL ARE AVAILABLE.', &
        '  PMEP WAS NOT EXECUTED' 
      return  
      end subroutine pmep 


      subroutine pmep1 
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:03:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
      implicit none
!-----------------------------------------------
!
!   DUMMY SUBROUTINE - THIS ROUTINE IS DESIGNED TO DO NOTHING
!
      return  
      end subroutine pmep1 


      subroutine pmepco(pp, ria, w, ui, co, nonzo, id) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      use permanent_arrays, only : nat, nfirst, nlast
      use molkst_C, only : numat
!**********************************************************************
! PMEPCO IS THE CORE SUBROUTINE OF THIS PROGRAM <PMEP>. IT CALCULATES
! THE MEP AT AN ARBITRALRY POSITION W(3).
! REF.  B. WANG AND G.P.FORD J.COMPT.CHEM. IN PRESS
!       G.P.FORD AND B. WANG J.COMPT.CHEM. 14(1993)1101
!                                      WRITTEN BY BINGZE WANG FEB 1993
!**********************************************************************
!***********************************************************************
!DECK MOPAC
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:03:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
!-----------------------------------------------
!   I n t e r f a c e   B l o c k s
!-----------------------------------------------
      use drotat_I 
      implicit none
!-----------------------------------------------
!   G l o b a l   P a r a m e t e r s
!-----------------------------------------------
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(in) :: nonzo 
      integer , intent(in) :: id 
      real(double) , intent(out) :: ui 
      real(double) , intent(in) :: pp(*) 
      real(double) , intent(in) :: ria(*) 
      real(double)  :: w(3) 
      real(double)  :: co(3,*) 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer :: j, mn, i, ia, ib, ni, i2, i1, k 
      real(double), dimension(10) :: e1b 
      real(double), dimension(nonzo) :: vp 
      real(double), dimension(107) :: alpw, aw 
      real(double) :: ev, enuclr, rr, xx, yy, zz, fnear, enuc 
!-----------------------------------------------
!                                    AM1 PARAMETERS (FOR H,C,N,O,F,CL)
      data alpw/ 2.92D0, 4*0.0D0, 4.36D0, 6.95D0, 9.22D0, 5.53D0, 0.0D0, 4*&
        0.0D0, 2.3D0, 2.6D0, 3.32D0, 17*0.0D0, 3.32D0, 72*0.0D0/  
      data aw/ 0.05D0, 4*0.0D0, 0.63D0, 0.64D0, 0.67D0, 0.29D0, 0.0D0, 4*0.0D0&
        , 0.45D0, 0.37D0, 0.31D0, 17*0.0D0, 0.31D0, 72*0.0D0/  
      data ev/ 23.061D0/  
!
      vp(:nonzo) = 0.0D0 
      mn = 0 
      enuclr = 0.D0 
      do i = 1, numat 
        ia = nfirst(i) 
        ib = nlast(i) 
        ni = nat(i) 
        if (id == 1) then 
          rr = ria(i) 
        else 
          xx = w(1) - co(1,i) 
          yy = w(2) - co(2,i) 
          zz = w(3) - co(3,i) 
          rr = sqrt(xx*xx + yy*yy + zz*zz) 
        endif 
        fnear = 1.0D0 + exp((-alpw(ni)*(rr-aw(ni)))) 
!
        call drotat (ni, co(1,i), w, e1b, enuc, rr) 
        enuclr = enuclr + enuc*fnear 
        i2 = 0 
        do i1 = ia, ib 
          if (i1 - ia + 1 > 0) then 
            vp(mn+1:i1-ia+1+mn) = e1b(i2+1:i1-ia+1+i2) 
            i2 = i1 - ia + 1 + i2 
            mn = i1 - ia + 1 + mn 
          endif 
        end do 
      end do 
      mn = 0 
      ui = 0.0D0 
      do i = 1, numat 
        ia = nfirst(i) 
        ib = nlast(i) 
        do j = ia, ib 
          do k = ia, j 
            mn = mn + 1 
            if (k == j) then 
              ui = ui + pp(mn)*vp(mn) 
            else 
              ui = ui + 2.0D0*pp(mn)*vp(mn) 
            endif 
          end do 
        end do 
      end do 
      ui = (enuclr + ui)*ev 
!                                                       UI  IN KCAL/MOL
      return  
      end subroutine pmepco 


      subroutine surfa(co, potpt, nmep) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      use chanel_C, only : iw
      use molkst_C, only : keywrd
      use pmep_C, only : natom, ian
!***********************************************************************
!   THIS SUBROUTINE CALCULATED THE MOLECULAR SURFACE AND WAS LIFTED
!   FROM M. CONNOLLY'S PROGRAM BY U.C.SINGH AND P.A.KOLLMAN.
!   IN THIS MODIFIED VERSION IT GENERATES THE SAMPLE POINTS ON FOUR
!   LAYERS OF VAN DER WAAL'S SURFACES.
!                                     BY BINGZE WANG ON 19 AUGUST 1993
!***********************************************************************
!***********************************************************************
!DECK MOPAC
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:03:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
!-----------------------------------------------
!   I n t e r f a c e   B l o c k s
!-----------------------------------------------
      use collis_I 
      use reada_I 
      use mopend_I 
      use genvec_I 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(inout) :: nmep 
      real(double) , intent(in) :: co(3,*) 
      real(double) , intent(out) :: potpt(3,*) 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer , dimension(1) :: ias 
      integer ::  layer, ishel, i, ipoint, iatom, nnbr, jatom, ncon
      real(double), dimension(100) :: vander 
      real(double), dimension(3,1000) :: con 
      real(double), dimension(1) :: rad 
      real(double), dimension(3,200) :: cnbr 
      real(double), dimension(200) :: rnbr 
      real(double), dimension(3) :: ci, temp0 
      real(double), dimension(3,2) :: cw 
      real(double) :: scale, dens, scincr, pi, rw, den, ri, d2, mxmep = 0
      logical :: si 
!-----------------------------------------------
!
!     NEIGHBOR ARRAYS
!
!     THIS SAME DIMENSION FOR THE MAXIMUM NUMBER OF NEIGHBORS
!     IS USED TO DIMENSION ARRAYS IN THE LOGICAL FUNCTION COLLID
!
!
!              ARRAYS FOR ALL ATOMS, IATOM, JATOM AND KATOM COORDINATES
!                                        GEOMETRIC CONSTRUCTION VECTORS
!                                                     LOGICAL VARIABLES
!                                                     LOGICAL FUNCTIONS
!                                            DATA FOR VANDER VALL RADII 
      data scale/ 1.4D0/  
      data dens/ 1.0D0/  
      data scincr/ 0.20D0/  
      data layer/ 4/  
      data vander/ 1.20D0, 1.20D0, 1.37D0, 1.45D0, 1.45D0, 1.50D0, 1.50D0, &
        1.40D0, 1.35D0, 1.30D0, 1.57D0, 1.36D0, 1.24D0, 1.17D0, 1.80D0, 1.75D0&
        , 1.70D0, 17*0.0D0, 2.3D0, 65*0.0D0/  
!
      pi = 4.D0*atan(1.D0) 
!                                    INSERT VAN DER WAAL RADII FOR ZINC
      vander(30) = 1.00D0 
!
      if (index(keywrd,'SCALE=') /= 0) scale = reada(keywrd,index(keywrd,&
        'SCALE=')) 
      if (index(keywrd,'DEN=') /= 0) dens = reada(keywrd,index(keywrd,'DEN=')) 
      if (index(keywrd,'SCINCR=') /= 0) scincr = reada(keywrd,index(keywrd,&
        'SCINCR=')) 
      if (index(keywrd,'NSURF=') /= 0) layer = nint(reada(keywrd,index(keywrd,&
        'NSURF='))) 
!
      do ishel = 1, layer 
!                         ONLY VAN DER WAALS' TYPE SURFACE IS GENERATED
        rw = 0.0D0 
        den = dens 
        do i = 1, natom 
          ipoint = ian(i) 
          rad(i) = vander(ipoint)*scale 
          if (rad(i) < 0.01D0) write (iw, &
      '(T2,''VAN DER WAALS'''' RADIUS FOR ATOM '',I3,          '' IS ZERO, SUPP&
      &LY A VALUE IN SUBROUTINE SURFAC)'' )') 
          ias(i) = 2 
        end do 
!
!     BIG LOOP FOR EACH ATOM
!
        do iatom = 1, natom 
          if (ias(iatom) == 0) cycle  
!
!     TRANSFER VALUES FROM LARGE ARRAYS TO IATOM VARIABLES
!
          ri = rad(iatom) 
          si = ias(iatom) == 2 
          ci = co(:,iatom) 
!                                GATHER THE NEIGHBORING ATOMS OF IATOM
          nnbr = 0 
          do jatom = 1, natom 
            if (iatom==jatom .or. ias(jatom)==0) cycle  
            d2 = (ci(1)-co(1,jatom))**2 + (ci(2)-co(2,jatom))**2 + (ci(3)-co(3,&
              jatom))**2 
            if (d2 >= (2*rw + ri + rad(jatom))**2) cycle  
!
!     WE HAVE A NEW NEIGHBOR
!     TRANSFER ATOM COORDINATES, RADIUS AND SURFACE REQUEST NUMBER
!
            nnbr = nnbr + 1 
            if (nnbr > 200) then 
              write (iw, '(''ERROR'',2X,''TOO MANY NEIGHBORS:'',I5)') nnbr 
              call mopend ('TOO MANY NEIGHBORS') 
              return  
            endif 
            cnbr(:,nnbr) = co(:,jatom) 
            rnbr(nnbr) = rad(jatom) 
          end do 
!
!     CONTACT SURFACE
!
          if (.not.si) cycle  
          ncon = int((4*pi*ri**2)*den) 
          ncon = min0(1000,ncon) 
!
!     THIS CALL MAY DECREASE NCON SOMEWHAT
!
          if (ncon == 0) then 
            write (iw, '(T2,''VECTOR LENGTH OF ZERO IN SURFAC'')') 
            call mopend ('VECTOR LENGTH OF ZERO IN SURFAC') 
            return  
          endif 
          call genvec (con, ncon) 
!
!     CONTACT PROBE PLACEMENT LOOP
!
          do i = 1, ncon 
            cw(:,1) = ci + (ri + rw)*con(:,i) 
!
!     CHECK FOR COLLISION WITH NEIGHBORING ATOMS
!
            if (collis(cw(1,1),rw,cnbr,rnbr,nnbr,1)) cycle  
            temp0 = ci + ri*con(:,i) 
!
!     STORE POINT IN POTPT AND INCREMENT NMEP
!
            nmep = nmep + 1 
            if (nmep > mxmep) go to 100  
            potpt(1,nmep) = temp0(1) 
            potpt(2,nmep) = temp0(2) 
            potpt(3,nmep) = temp0(3) 
          end do 
        end do 
        scale = scale + scincr 
      end do 
      return  
  100 continue 
      write (iw, 110) 
      call mopend ('ERROR - TOO MANY POINTS GENERATED IN SURFAC.') 
      return  
  110 format(/,'ERROR - TO MANY POINTS GENERATED IN SURFAC'/,&
        '    REDUCE NSURF, SCALE, DEN, OR SCINCR') 
      end subroutine surfa 


      logical function collis (cw, rw, cnbr, rnbr, nnbr, ishape) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
!****************************************************************
!     COLLISION CHECK OF PROBE WITH NEIGHBORING ATOMS
!     FOR CONNOLLY SURFACE ONLY.
!****************************************************************
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:03:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(in) :: nnbr 
      integer , intent(in) :: ishape 
      real(double) , intent(in) :: rw 
      real(double) , intent(in) :: cw(3) 
      real(double) , intent(in) :: cnbr(3,200) 
      real(double) , intent(in) :: rnbr(200) 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer :: i 
      real(double) :: sumrad, vect1, vect2, vect3, sr2, dd2 
!-----------------------------------------------
!
      collis = .FALSE. 
      if (nnbr <= 0) return  
!                 CHECK WHETHER PROBE IS TOO CLOSE TO ANY NEIGHBOR
      if (ishape == 3) then 
      else 
        do i = 1, nnbr 
          sumrad = rw + rnbr(i) 
          vect1 = dabs(cw(1)-cnbr(1,i)) 
          if (vect1 >= sumrad) cycle  
          vect2 = dabs(cw(2)-cnbr(2,i)) 
          if (vect2 >= sumrad) cycle  
          vect3 = dabs(cw(3)-cnbr(3,i)) 
          if (vect3 >= sumrad) cycle  
          sr2 = sumrad**2 
          dd2 = vect1**2 + vect2**2 + vect3**2 
          if (dd2 < sr2) go to 20 
        end do 
      endif 
      return  
   20 continue 
      collis = .TRUE. 
      return  
      end function collis 


!
      subroutine drepp2(ni, rij, ri, core) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      USE parameters_C, only : natorb, tore, am, ad, aq, dd, qq
      USE funcon_C, only : a0, ev
!*********************************************************************
! DREPP2 CALCULATES THE INTEGRAL FOR PMEP.
! REFERENCE G.P.FORD AND B.WANG, J.COMPUT.CHEM. 14 (1993)1101.
!                            WRITTEN BY BINGZE WANG, 10 OCTOBER 1991.
!*********************************************************************
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:03:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(in) :: ni 
      real(double) , intent(in) :: rij 
      real(double) , intent(out) :: ri(22) 
      real(double) , intent(out) :: core(4,2) 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer :: i 
      real(double), dimension(72) :: arg, sqr 
      real(double) ::  ev1, ev2, pp, r, aee, da, qa, ade, aqe, rsq, xxx&
        , ee 
!----------------------------------------------- 
      ev1 = ev*0.5D0 
      ev2 = ev1*0.5D0 
      data pp/ 0.5D00/  
      r = rij/a0 
      if (natorb(ni) < 3) then 
!                                           HYDROGEN - HYDROGEN (SS/SS)
        aee = pp/am(ni) 
        aee = aee*aee 
        ri(1) = ev/dsqrt(r*r + aee) 
        core(1,1) = ri(1) 
        core(1,2) = tore(ni)*ri(1) 
      else 
!                                                 HEAVY ATOM - HYDROGEN
        aee = pp/am(ni) 
        aee = aee*aee 
        da = dd(ni) 
        qa = qq(ni)*2.0D0 
        ade = pp/ad(ni) 
        ade = ade*ade 
        aqe = pp/aq(ni) 
        aqe = aqe*aqe 
        rsq = r*r 
        arg(1) = rsq + aee 
        xxx = r + da 
        arg(2) = xxx*xxx + ade 
        xxx = r - da 
        arg(3) = xxx*xxx + ade 
        xxx = r + qa 
        arg(4) = xxx*xxx + aqe 
        xxx = r - qa 
        arg(5) = xxx*xxx + aqe 
        arg(6) = rsq + aqe 
        arg(7) = arg(6) + qa*qa 
        do i = 1, 7 
          sqr(i) = dsqrt(arg(i)) 
        end do 
        ee = ev/sqr(1) 
        ri(1) = ee 
        ri(2) = ev1/sqr(2) - ev1/sqr(3) 
        ri(3) = ee + ev2/sqr(4) + ev2/sqr(5) - ev1/sqr(6) 
        ri(4) = ee + ev1/sqr(7) - ev1/sqr(6) 
        core(1,1) = ri(1) 
        core(2,1) = ri(2) 
        core(3,1) = ri(3) 
        core(4,1) = ri(4) 
        core(1,2) = tore(ni)*ri(1) 
      endif 
      return  
      end subroutine drepp2 


!
      subroutine drotat(ni, xi, xj, e1b, enuc, rij) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      USE rotate_C, only : ccore, css1, csp1, cpps1, cppp1
      use parameters_C, only : natorb, tore
!**********************************************************************
!  SUBROUTINE DROTAT TRANSFORMS THE INTEGRALS FROM LOCAL COORDINATES
!  INTO MOLECULAR COORDINATES FOR PMEP COMPUTATIONS.
!                                  WRITTEN BY BINGZE WANG, NOV. 1991
!**********************************************************************
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:03:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
!-----------------------------------------------
!   I n t e r f a c e   B l o c k s
!-----------------------------------------------
      use drepp2_I 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer  :: ni 
      real(double) , intent(out) :: enuc 
      real(double)  :: rij 
      real(double) , intent(in) :: xi(3) 
      real(double) , intent(in) :: xj(3) 
      real(double) , intent(out) :: e1b(10) 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      real(double), dimension(3) :: x, y, z 
      real(double), dimension(22) :: ri 
      real(double) :: rijx, gam, a, xx11, xx21, xx22, xx31, xx32, xx33, yy11, &
        yy21, yy22, zz11, zz21, zz22, zz31, zz32, zz33, yyzz11, yyzz21, yyzz22 
!-----------------------------------------------
      x(1) = xi(1) - xj(1) 
      x(2) = xi(2) - xj(2) 
      x(3) = xi(3) - xj(3) 
      rijx = rij 
!                                   COMPUTE INTEGRALS IN DIATOMIC FRAME
      call drepp2 (ni, rij, ri, ccore) 
!
      gam = ri(1) 
      a = 1.D0/rijx 
      x(1) = x(1)*a 
      x(2) = x(2)*a 
      x(3) = x(3)*a 
      if (dabs(x(3)) > 0.99999D0) then 
        x(3) = dsign(1.D0,x(3)) 
        y(1) = 0.D0 
        y(2) = 1.D0 
        y(3) = 0.D0 
        z(1) = 1.D0 
        z(2) = 0.D0 
        z(3) = 0.D0 
      else 
        z(3) = dsqrt(1.D0 - x(3)*x(3)) 
        a = 1.D0/z(3) 
        y(1) = -a*x(2)*dsign(1.D0,x(1)) 
        y(2) = dabs(a*x(1)) 
        y(3) = 0.D0 
        z(1) = -a*x(1)*x(3) 
        z(2) = -a*x(2)*x(3) 
      endif 
      if (natorb(ni) > 1) then 
        xx11 = x(1)*x(1) 
        xx21 = x(2)*x(1) 
        xx22 = x(2)*x(2) 
        xx31 = x(3)*x(1) 
        xx32 = x(3)*x(2) 
        xx33 = x(3)*x(3) 
        yy11 = y(1)*y(1) 
        yy21 = y(2)*y(1) 
        yy22 = y(2)*y(2) 
        zz11 = z(1)*z(1) 
        zz21 = z(2)*z(1) 
        zz22 = z(2)*z(2) 
        zz31 = z(3)*z(1) 
        zz32 = z(3)*z(2) 
        zz33 = z(3)*z(3) 
        yyzz11 = yy11 + zz11 
        yyzz21 = yy21 + zz21 
        yyzz22 = yy22 + zz22 
      endif 
!                               ROTATE THE NUCLEAR ATTRACTION INTEGRALS
      e1b(1) = -css1 
      if (natorb(ni) == 4) then 
        e1b(2) = -csp1*x(1) 
        e1b(3) = (-cpps1*xx11) - cppp1*yyzz11 
        e1b(4) = -csp1*x(2) 
        e1b(5) = (-cpps1*xx21) - cppp1*yyzz21 
        e1b(6) = (-cpps1*xx22) - cppp1*yyzz22 
        e1b(7) = -csp1*x(3) 
        e1b(8) = (-cpps1*xx31) - cppp1*zz31 
        e1b(9) = (-cpps1*xx32) - cppp1*zz32 
        e1b(10) = (-cpps1*xx33) - cppp1*zz33 
      endif 
      enuc = tore(ni)*gam 
      return  
      end subroutine drotat 


!
      subroutine genvec(u, n) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
!*******************************************************************
!  GENERATE UNIT VECTORS OVER SPHERE. FOR CONNOLLY SURFACE ONLY
!*******************************************************************
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:03:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(inout) :: n 
      real(double) , intent(out) :: u(3,n) 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer :: nequat, nvert, nu, i, nhor, j 
      real(double) :: pi, fi, z, xy, fj, x, y 
!-----------------------------------------------
      pi = 4.D0*atan(1.D0) 
      nequat = int(sqrt(n*pi)) 
      nvert = nequat/2 
      nu = 0 
      l20: do i = 1, nvert + 1 
        fi = (pi*(i - 1))/nvert 
        z = cos(fi) 
        xy = sin(fi) 
        nhor = int(nequat*xy) 
        nhor = max0(1,nhor) 
        do j = 1, nhor 
          fj = (2.D0*pi*(j - 1))/nhor 
          x = dcos(fj)*xy 
          y = dsin(fj)*xy 
          if (nu >= n) exit  l20 
          nu = nu + 1 
          u(1,nu) = x 
          u(2,nu) = y 
          u(3,nu) = z 
        end do 
      end do l20 
      n = nu 
      return  
      end subroutine genvec 


!
      subroutine grids(co, potpt, nmep) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      use chanel_C, only : iw
      use pmep_C, only : natom, ian
!********************************************************************
!   THIS SUBROUTINE CALCULATES THE WILLIAMS SURFACE OR GRIDS. IT IS
!   LIFTED FROM <ESP> BY B.H.BESLER AND K.M.MERZ.
!********************************************************************
!***********************************************************************
!DECK MOPAC
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:03:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
!-----------------------------------------------
!   I n t e r f a c e   B l o c k s
!-----------------------------------------------
      use mopend_I 
      implicit none
!-----------------------------------------------
!   G l o b a l   P a r a m e t e r s
!-----------------------------------------------
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(inout) :: nmep 
      real(double) , intent(in) :: co(3,*) 
      real(double) , intent(out) :: potpt(3,*) 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer :: i, ia, npnt, l, jz 
      real(double), dimension(53) :: vderw 
      real(double), dimension(100) :: dist 
      real(double), dimension(3) :: xmin, xmax 
      real(double) :: shell, grid, closer, vdmax, xstart, ystart, zstart, zgrid&
        , ygrid, xgrid 
!----------------------------------------------- 
!
      data vderw/ 53*0.0D0/  
      vderw(1) = 2.4D0 
      vderw(5) = 3.0D0 
      vderw(6) = 2.9D0 
      vderw(7) = 2.7D0 
      vderw(8) = 2.6D0 
      vderw(9) = 2.55D0 
      vderw(15) = 3.1D0 
      vderw(16) = 3.05D0 
      vderw(17) = 3.0D0 
      vderw(35) = 3.15D0 
      vderw(53) = 3.35D0 
      shell = 1.2D0 
      grid = 0.8D0 
      closer = 0.D0 
!     CHECK IF VDERW IS DEFINED FOR ALL ATOMS
!
      do i = 1, natom 
        if (vderw(ian(i)) == 0.0D0) go to 20 
      end do 
      go to 30 
   20 continue 
      write (iw, *) 'VAN DER WAALS'' RADIUS NOT DEFINED FOR ATOM', i 
      write (iw, *) 'IN WILLIAMS SURFACE ROUTINE PDGRID!' 
      call mopend (&
      'VAN DER WAALS'' RADIUS NOT DEFINED IN WILLIAMS SURFACE ROUTINE PDGRID!.'&
        ) 
      return  
!     NOW CREATE LIMITS FOR A BOX
   30 continue 
      xmin = 100000.0D0 
      xmax = -100000.0D0 
      do ia = 1, natom 
        where (co(:,ia) - xmin < 0.D0)  
          xmin = co(:,ia) 
        end where 
        where (co(:,ia) - xmax > 0.D0)  
          xmax = co(:,ia) 
        end where 
      end do 
!     ADD (OR SUBTRACT) THE MAXIMUM VDERW PLUS SHELL
      vdmax = 0.0D0 
      vdmax = dmax1(maxval(vderw),vdmax) 
      xmin = xmin - vdmax - shell 
      xmax = xmax + vdmax + shell 
! STEP GRID BACK FROM ZERO TO FIND STARTING POINTS
      xstart = 0.0D0 
      xstart = xstart - grid 
      do while(xstart > xmin(1)) 
        xstart = xstart - grid 
      end do 
      ystart = 0.0D0 
      ystart = ystart - grid 
      do while(ystart > xmin(2)) 
        ystart = ystart - grid 
      end do 
      zstart = 0.0D0 
      zstart = zstart - grid 
      do while(zstart > xmin(3)) 
        zstart = zstart - grid 
      end do 
      npnt = 0 
      zgrid = zstart 
  140 continue 
      ygrid = ystart 
  150 continue 
      xgrid = xstart 
  160 continue 
      do l = 1, natom 
        jz = ian(l) 
        dist(l) = sqrt((co(1,l)-xgrid)**2+(co(2,l)-ygrid)**2+(co(3,l)-zgrid)**2&
          ) 
!     REJECT GRID POINT IF ANY ATOM IS TOO CLOSE
        if (dist(l) < vderw(jz) - closer) go to 200 
      end do 
! BUT AT LEAST ONE ATOM MUST BE CLOSE ENOUGH
      do l = 1, natom 
        jz = ian(l) 
        if (dist(l) > vderw(jz) + shell) cycle  
        go to 190 
      end do 
      go to 200 
  190 continue 
      npnt = npnt + 1 
      nmep = nmep + 1 
      potpt(1,nmep) = xgrid 
      potpt(2,nmep) = ygrid 
      potpt(3,nmep) = zgrid 
  200 continue 
      xgrid = xgrid + grid 
      if (xgrid <= xmax(1)) go to 160 
      ygrid = ygrid + grid 
      if (ygrid <= xmax(2)) go to 150 
      zgrid = zgrid + grid 
      if (zgrid <= xmax(3)) go to 140 
      return  
      end subroutine grids 


      subroutine mepchg(co, potpt, nmep) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      USE permanent_arrays, only : ch, p
      USE elemts_C, only : elemnt 
      use chanel_C, only : iw
      use molkst_C, only : keywrd, ux, uy, uz, numat
      use funcon_C, only : fpc_9, a0, fpc_1, fpc_8, ev
      use pmep_C, only : natom, ian
!**********************************************************************
!  MEPCHG CALCULATES THE MEP CHARGES BY FITTING THE QUANTUM POTENTIAL
!  TO THE COULOMB POTENTIAL.
!  REF.  B. WANG AND G.P.FORD J.COMPT.CHEM. IN PRESS.
!        G.P.FORD AND B. WANG J.COMPT.CHEM. 14(1993)1101.
!                                       BINGZE WANG ON 19 AUGUST 1993
!**********************************************************************
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:03:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
!-----------------------------------------------
!   I n t e r f a c e   B l o c k s
!-----------------------------------------------
      use reada_I 
      use packp_I 
      use pmepco_I 
      use osinv_I 
      implicit none
!-----------------------------------------------
!   G l o b a l   P a r a m e t e r s
!-----------------------------------------------
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(in) :: nmep 
      real(double)  :: co(3,*) 
      real(double)  :: potpt(3,*) 
      real(double)  :: al(1000) 
      real(double)  :: a(numat + 4,numat + 4) 
      real(double)  :: d(numat,numat) 
      real(double)  :: d1(numat,numat) 
      logical       :: cequiv(numat,numat) 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer :: iz, natom0, k, i, nonzo, ip, j, l, ieq 
      real(double), dimension(numat) :: q 
      real(double), dimension(1) :: ep 
      real(double), dimension(numat + 4) :: b 
      real(double), dimension(1) :: pp 
      real(double), dimension(numat) :: qsc, qq 
      real(double) :: rms, rrms, dipx, dipy, dipz, au, cf, bohr1, au1, dx&
        , dy, dz, xk, yk, zk, xp, yp, zp, dki, ui, ajk, det,qi, epc, epi, dip 
      logical :: idip 
!-----------------------------------------------
      data iz/ 0/  
      data rms/ 0.0D0/  
      data rrms/ 0.0D0/  
      data dipx/ 0.0D0/  
      data dipy/ 0.0D0/  
      data dipz/ 0.0D0/  
      data idip/ .FALSE./  
      au = ev*fpc_9 
!     cf = 5.2917715D0*1.601917D0/3.33564D0 
      cf = fpc_1*a0*fpc_8*1.D-10 
      bohr1 = 1.0D0/a0 
      au1 = 1.0D0/au 
      natom0 = natom + 1 
!
      write (iw, 10) 
   10 format(/,/,1x,'ATOMIC CHARGES DERIVED FROM MOLECULAR',&
        ' ELECTROSTATIC POTENTIAL') 
      if (index(keywrd,' WILLIAMS') /= 0) then 
        write (iw, '(8X,''(WILLIAMS SURFACES)''/)') 
      else 
        write (iw, '(8X,''(CONNOLLY SURFACES)''/)') 
      endif 
!
      if (index(keywrd,' CHARGE=') /= 0) iz = nint(reada(keywrd,index(keywrd,&
        ' CHARGE='))) 
!                                                  DIPOLAR CONSTRAINTS
      if (index(keywrd,'DIPOLE') /= 0) then 
        if (iz == 0) then 
          idip = .TRUE. 
          natom0 = natom + 4 
          write (iw, '(/12X,''DIPOLE CONSTRAINTS WILL BE USED'',/)') 
          dx = ux 
          dy = uy 
          dz = uz 
          if (index(keywrd,'DIPX=') /= 0) dx = reada(keywrd,index(keywrd,&
            'DIPX=')) 
          if (index(keywrd,'DIPY=') /= 0) dy = reada(keywrd,index(keywrd,&
            'DIPY=')) 
          if (index(keywrd,'DIPZ=') /= 0) dz = reada(keywrd,index(keywrd,&
            'DIPZ=')) 
        else 
          write (iw, *) ' DIPOLE CONSTRAINTS NOT USED FOR CHARGED MOLECULE' 
        endif 
      endif 
      do k = 1, natom 
        xk = co(1,k) 
        yk = co(2,k) 
        zk = co(3,k) 
        do i = 1, nmep 
          xp = potpt(1,i) - xk 
          yp = potpt(2,i) - yk 
          zp = potpt(3,i) - zk 
          dki = sqrt(xp*xp + yp*yp + zp*zp) 
          d(k,i) = dki 
          d1(k,i) = a0/dki 
        end do 
      end do 
!
!******  SET UP THE LINEAR EQUATION A*Q=B  *******
!                                       MEP AT SAMPLE POINTS & B MATRIX
      call packp (p, pp, nonzo) 
      b(:natom) = 0.0D0 
      do ip = 1, nmep 
        call pmepco (pp, d(1,ip), potpt(1,ip), ui, co, nonzo, 1) 
        ep(ip) = ui*au1 
        b(:natom) = b(:natom) + ep(ip)*d1(:natom,ip) 
      end do 
      b(natom+1) = dble(iz) 
      if (idip) then 
        b(natom+2) = dx/cf 
        b(natom+3) = dy/cf 
        b(natom+4) = dz/cf 
      endif 
!                                                      THE A(J,K) ARRAY
      do k = 1, natom 
        do j = 1, k 
          ajk = 0.0D0 
          ajk = sum(d1(k,:nmep)*d1(j,:nmep)) 
          a(k,j) = ajk 
          a(j,k) = ajk 
        end do 
        a(natom+1,k) = 1.D0 
        a(k,natom+1) = 1.D0 
        if (.not.idip) cycle  
        a(natom+2,k) = co(1,k)*bohr1 
        a(natom+3,k) = co(2,k)*bohr1 
        a(natom+4,k) = co(3,k)*bohr1 
        a(k,natom+2) = a(natom+2,k) 
        a(k,natom+3) = a(natom+3,k) 
        a(k,natom+4) = a(natom+4,k) 
      end do 
      a(natom+1,natom+1) = 0.D0 
      if (idip) then 
        a(natom+2,natom+2) = 0.D0 
        a(natom+3,natom+3) = 0.D0 
        a(natom+4,natom+4) = 0.D0 
      endif 
!                                                            SOLVE AQ=B
      l = 0 
      do i = 1, natom0 
        al(l+1:natom0+l) = a(i,:natom0) 
        l = natom0 + l 
      end do 
      call osinv (al, natom0, det) 
      l = 0 
      do i = 1, natom 
        qi = 0.0D0 
        if (natom0 > 0) then 
          qi = sum(al(l+1:natom0+l)*b(:natom0)) 
          l = natom0 + l 
        endif 
        q(i) = qi 
      end do 
      qi = det ! dummy use of det
!                               AVERAGE CHARGES EQUIVALENT BY SYMMETRY
      if (index(keywrd,'SYMAVG') /= 0) then 
        do i = 1, natom 
          do j = 1, natom 
            cequiv(i,j) = .FALSE. 
            if (abs(abs(ch(i))-abs(ch(j))) >= 1.D-5) cycle  
            cequiv(i,j) = .TRUE. 
          end do 
        end do 
        do i = 1, natom 
          ieq = 0 
          qsc(i) = 0.D0 
          do j = 1, natom 
            if (.not.cequiv(i,j)) cycle  
            qsc(i) = qsc(i) + abs(q(j)) 
            ieq = ieq + 1 
          end do 
          qq(i) = q(i)/abs(q(i))*qsc(i)/ieq 
        end do 
        q(:natom) = qq(:natom) 
      endif 
!                              ROOT MEAN SQUARE (RMS) AND RELATIVE RMS
      do i = 1, nmep 
        epi = ep(i) 
        epc = sum(q(:natom)*d1(:natom,i)) 
        epc = epc - epi 
        rms = rms + epc*epc 
        rrms = rrms + epi*epi 
      end do 
      rms = sqrt(rms/nmep) 
      rrms = rms/sqrt(rrms/nmep) 
      rms = rms*au 
!
      write (iw, '(3X,''ATOM NO.    TYPE    CHARGE'')') 
      do i = 1, natom 
        write (iw, '(5X,I2,9X,A2,1X,F10.4)') i, elemnt(ian(i)), q(i) 
      end do 
!
      write (iw, '(/2X,A,4X,I6)') 'NUMBER OF POINTS ', nmep 
      write (iw, '(2X,A,4X,F9.4)') 'RMS DEVIATION ', rms 
      write (iw, '(2X,A,3X,F9.4)') 'RRMS DEVIATION ', rrms 
!
      if (iz /= 0) return  
!                                    DIPOLE MOMENT FOR NEUTRAL MOLECULE
      dipx = dipx + dot_product(co(1,:natom),q(:natom)) 
      dipy = dipy + dot_product(co(2,:natom),q(:natom)) 
      dipz = dipz + dot_product(co(3,:natom),q(:natom)) 
      dipx = dipx*bohr1 
      dipy = dipy*bohr1 
      dipz = dipz*bohr1 
      dip = sqrt(dipx*dipx + dipy*dipy + dipz*dipz) 
      write (iw, '(2/1X,''DIPOLE MOMENT EVALUATED FROM THE MEP CHARGES'')') 
      write (iw, '(7X,''D(X)     D(Y)     D(Z)     TOTAL'')') 
      write (iw, '(3X,4F9.4)') dipx*cf, dipy*cf, dipz*cf, dip*cf 
!
      return  
      end subroutine mepchg 


!
      subroutine mepmap(c1) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      use molkst_C, only : keywrd, moperr, numat, lm61
      use permanent_arrays, only : nat, p
      use chanel_C, only : iw, is
      use elemts_C, only : elemnt
!*********************************************************************
!  SUBROUTINE MEPMAP CALCULATES THE MEP MINIMA AND GENERATES THE
!  CONROUR DATA IN A DEFINED PLANE.
!  REF.  G.P.FORD AND B. WANG J.COMPT.CHEM. 14(1993)1101.
!                                    WRITTEN BY BINGZE WANG, DEC 1992
!*********************************************************************
!***********************************************************************
!DECK MOPAC
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:03:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
!-----------------------------------------------
!   I n t e r f a c e   B l o c k s
!-----------------------------------------------
      use meprot_I 
      use packp_I 
      use pmepco_I 
      implicit none
!-----------------------------------------------
!   G l o b a l   P a r a m e t e r s
!-----------------------------------------------
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      real(double)  :: c1(3,numat) 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer , dimension(numat) :: mx, my 
      integer :: need1, natm, icase, iback, i, nonzo, npx, npy, k, ip, &
        m, n, imin, ny, minima, j 
      real(double), dimension(lm61) :: pp 
      real(double), dimension(3) :: w, r0 
      real(double), dimension(3,3) :: t 
      real(double), dimension(numat) :: ria, vmin 
      real(double), dimension(3,numat) :: cw 
      real(double), dimension(200) :: uu 
      real(double), dimension(3,numat) :: cmep 
      real(double) :: step, cut, z0, xm, ym, t11, t12, t13, t21, t22, t23, t31&
        , t32, t33, xx0, yy0, zz0, xxw, yyw, zzw, step1, xx1, yy1, zz1, stepm, &
        xx2, yy2, zz2, stepn, rmin, rr, ui 
      logical :: prtmep, minmep 
!-----------------------------------------------
      data t/ 1.0D0, 3*0.0D0, 1.0D0, 3*0.0D0, 1.0D0/  
      data step/ 0.1D0/  
      data need1/ 0/  
      data natm/ 0/  
      data r0/ 3*0.0D0/  
      data cut/ 999.0D0/  
      data icase/ 0/  
      data z0/ 0.0D0/  
      data iback/ 0/  
      write (iw, 10) 
   10 format(/,/,/,13x,'MOLCULAR ELECTROSTATIC POTENTIAL',/,/,1x,&
        'REFERENCES  B.WANG AND G.P.FORD J.COMPT.CHEM. IN PRESS',/,13x,&
        'G.P.FORD AND B.WANG J.COMPT.CHEM. 14(1993)1101') 
      call meprot (c1, r0, t, xm, ym, icase, step, cmep, z0, iback) 
      if (moperr) return  
      if (iback > 0) return  
      prtmep = index(keywrd,' PRTMEP') /= 0 
      minmep = index(keywrd,' MINMEP') /= 0 
      cw(1,:numat) = cut 
      cw(2,:numat) = cut 
      cw(3,:numat) = cut 
      vmin(:numat) = cut 
!
      call packp (p, pp, nonzo) 
!
      npx = int(xm/step)*2 + 1 
      if (icase==2 .or. icase==3) then 
        ym = ym + 3.0D0 
        npy = int(ym/step) + 1 
      else 
        npy = int(ym/step)*2 + 1 
      endif 
      if (prtmep) then 
        write (is, 30) numat, npx, npy, (-xm), (-ym), step 
   30   format(1x,3i5,3f8.2,/) 
        write (is, 130) npx, npy, npx*npy, z0, (-xm), step, (-ym), step 
        write (is, 140) 
        write (is, 150) (i,nat(i),(cmep(k,i),k=1,2),i=1,numat) 
        write (is, *) 
      endif 
!                                   CREATE THE POINTS AND CALCULATE MEP
      ip = 0 
      t11 = t(1,1) 
      t12 = t(1,2) 
      t13 = t(1,3) 
      t21 = t(2,1) 
      t22 = t(2,2) 
      t23 = t(2,3) 
      t31 = t(3,1) 
      t32 = t(3,2) 
      t33 = t(3,3) 
      xx0 = z0*t31 
      yy0 = z0*t32 
      zz0 = z0*t33 
      xxw = xx0 + r0(1) 
      yyw = yy0 + r0(2) 
      zzw = zz0 + r0(3) 
      step1 = step 
   40 continue 
      xx1 = xx0 + r0(1) 
      yy1 = yy0 + r0(2) 
      zz1 = zz0 + r0(3) 
!
      do m = 1, npx 
        stepm = (m - 1)*step1 
        xx2 = xx1 + stepm*t11 
        yy2 = yy1 + stepm*t12 
        zz2 = zz1 + stepm*t13 
        l60: do n = 1, npy 
          uu(n) = cut 
          stepn = (n - 1)*step1 
          w(1) = xx2 + stepn*t21 
          w(2) = yy2 + stepn*t22 
          w(3) = zz2 + stepn*t23 
          if (need1 == 0) then 
!                                          CHECK IF TOO CLOSE TO NUCLEI
            rmin = 81.0D0 
            do i = 1, numat 
              rr = (w(1)-c1(1,i))**2 + (w(2)-c1(2,i))**2 + (w(3)-c1(3,i))**2 
              if (rr < 0.25D0) cycle  l60 
              if (nat(i)>1 .and. rr<0.36D0) cycle  l60 
              ria(i) = sqrt(rr) 
              if (rmin <= rr) cycle  
              rmin = rr 
              imin = i 
            end do 
            call pmepco (pp, ria, w, ui, c1, nonzo, 1) 
            uu(n) = ui 
            if (ui < vmin(imin)) then 
              vmin(imin) = ui 
              cw(1,imin) = w(1) 
              cw(2,imin) = w(2) 
              cw(3,imin) = w(3) 
              mx(imin) = m 
              my(imin) = n 
            endif 
          else 
            call pmepco (pp, ria, w, ui, c1, nonzo, 0) 
            if (ui < vmin(natm)) then 
              vmin(natm) = ui 
              cw(1,natm) = w(1) 
              cw(2,natm) = w(2) 
              cw(3,natm) = w(3) 
            endif 
          endif 
          ip = ip + 1 
        end do l60 
        if (.not.(need1==0 .and. prtmep)) cycle  
        write (is, 160) (uu(ny),ny=1,npy) 
      end do 
!
      if (need1 == 0) write (iw, 170) npx, npy 
      if (prtmep .and. need1==0) write (iw, *) &
        '=> CONTOUR FILE IS PRINTED ON CHANNEL 7' 
      if (need1 <= 0) then 
!                                               REMOVE THE FALSE MINIMA
        minima = 0 
        l90: do i = 1, numat 
          if (vmin(i) > 0.0D0) cycle  l90 
          do m = mx(i) - 1, mx(i) + 1 
            stepm = (m - 1)*step 
            xx2 = xxw + stepm*t11 
            yy2 = yyw + stepm*t12 
            zz2 = zzw + stepm*t13 
            do n = my(i) - 1, my(i) + 1 
              stepn = (n - 1)*step 
              w(1) = xx2 + stepn*t21 
              w(2) = yy2 + stepn*t22 
              w(3) = zz2 + stepn*t23 
              ip = ip + 1 
              call pmepco (pp, ria, w, ui, c1, nonzo, 0) 
              if (ui >= vmin(i) - 0.001D0) cycle  
              vmin(i) = 99.0D0 
              cycle  l90 
            end do 
          end do 
          minima = minima + 1 
        end do l90 
        if (minima == 0) then 
          write (iw, *) ' NO MEP MINIMUM FOUND IN THIS PLANE' 
          return  
        endif 
        if (.not.minmep) go to 110 
        need1 = 1 
        step1 = step*0.2D0 
        npx = 11 
        npy = 11 
      endif 
      natm = natm + 1 
      if (natm > numat) go to 110 
      do while(vmin(natm) > 0.0D0) 
        natm = natm + 1 
        if (natm > numat) go to 110 
      end do 
      r0(1) = cw(1,natm) - step*(t11 + t21) 
      r0(2) = cw(2,natm) - step*(t12 + t22) 
      r0(3) = cw(3,natm) - step*(t13 + t23) 
      go to 40 
  110 continue 
      if (need1 > 0) write (iw, 180) ip 
      write (iw, 190) 
      do i = 1, numat 
        if (vmin(i) >= 0.0D0) cycle  
        write (iw, 200) i, elemnt(nat(i)), vmin(i), dsqrt((c1(1,i)-cw(1,i))**2+&
          (c1(2,i)-cw(2,i))**2+(c1(3,i)-cw(3,i))**2), (cw(j,i),j=1,3) 
      end do 
      return  
  130 format(22x,'INSTRUCTION',/,1x,'1) NX*NY = ',i3,'*',i3,' =',i6,' GRIDS;',/&
        ,1x,'2) NY VALUES IN EACH OF THE NX BLOCKS;',/,1x,&
        '3) X,Y COORDINATES (Z=',f6.2,' ) OF THE GRIDS:',/,9x,'X(I)=',f8.2,'+',&
        f6.2,'*(I-1)    I=1,2,...,NX',/,9x,'Y(J)=',f8.2,'+',f6.2,&
        '*(J-1)    I=1,2,...,NY') 
  140 format(1x,'4) THE MOLECULAR COORDINATES (X,Y)',&
        ' ON THE 2D-MEP CONTOUR MAP') 
  150 format(9x,2i4,2f12.5) 
  160 format(6f11.5) 
  170 format(/,1x,'GRIDS NX*NY=',i3,' *',i3) 
  180 format(1x,'TOTAL NUMBER OF THE POINTS CALCULATED ',i8) 
  190 format(/,1x,'MINIMA IN THE SPECIFIED PLANE',/,5x,&
        'ATOM       UMIN      DISTANCE',10x,'XYZ COORDINATE',/,15x,&
        'KCAL/MOL     ANG',14x,'IN MOL COORD') 
  200 format(3x,i3,2x,a2,2x,f9.1,4x,f6.2,4x,3f9.3)  
      end subroutine mepmap 


!
      subroutine meprot(c, r0, t, xm, ym, icase, step, c1, z0, iback) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      use molkst_C, only : keywrd, numat
      use permanent_arrays, only : nat
      use chanel_C, only : iw, ir
!*********************************************************************
! MEPROT ROTATES THE MOLECULE TO CHOOSE THE PLANE IN WHICH MEP IS
! TO BE COMPUTED.
!                                     BY BINGZE WANG  28 OCT 1992
!*********************************************************************
!***********************************************************************
!DECK MOPAC
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:03:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
!-----------------------------------------------
!   I n t e r f a c e   B l o c k s
!-----------------------------------------------
      use mopend_I 
      implicit none
!-----------------------------------------------
!   G l o b a l   P a r a m e t e r s
!-----------------------------------------------
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer  :: icase 
      integer , intent(out) :: iback 
      real(double) , intent(out) :: xm 
      real(double) , intent(out) :: ym 
      real(double) , intent(in) :: step 
      real(double)  :: z0 
      real(double) , intent(in) :: c(3,*) 
      real(double) , intent(inout) :: r0(3) 
      real(double) , intent(inout) :: t(3,3) 
      real(double) , intent(out) :: c1(3,*) 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer ::  n1, n2, n3, i, k, j, is, il 
      real(double), dimension(3) :: c0 
      real(double) :: x2, y2, z2, rr2, r2, r21, x3, y3, z3, rr3, r3, r31, cos1&
        , p41, x34, y34, z34, r341, x6, y6, z6, x62, y62, z62, r621, x4, y4, z4&
        , x63, y63, z63, r631, r41, z5, y5, x5, r51, xi, yi, cs, cl 
!----------------------------------------------- 
      data c0/ 3*0.0D0/  
!
   10 format(/,1x,'INPUT CARD FOR PMEPR: ICASE,I,J,K,Z0 =',4i4,f8.2) 
   20 format(1x,'ICASE SHOULD BE 1,2, OR 3 AS PMEPR IS SPECIFIED',/,1x,&
        'PMEPR WAS NOT EXECUTED') 
   30 format(1x,'THE THREE REFERENTIAL ATOMS ARE UNREASONABLE, ',/,1x,&
        'PMEPR WAS NOT EXECUTED') 
      if (index(keywrd,' PMEPR') /= 0) then 
        read (ir, *) icase, n1, n2, n3, z0 
        write (iw, 10) icase, n1, n2, n3, z0 
        if (icase<1 .or. icase>3) then 
          write (iw, 20) 
          iback = 1 
          return  
        endif 
        if (n1==n2 .or. n1==n3 .or. n2==n3 .or. n1>numat .or. n2>numat .or. n3>&
          numat) then 
          write (iw, 30) 
          iback = 1 
          return  
        endif 
        if (icase == 1) then 
          if (abs(z0) < 0.0001D0) then 
            write (iw, 40) n1, n2, n3 
          else 
            write (iw, 50) z0, n1, n2, n3 
          endif 
        endif 
   40   format(1x,'MEPS ARE IN THE PLANE DEFINED BY ATOMS',3i4) 
   50   format(1x,'MEPS ARE IN THE PLANE',f6.2,' ABOVE THAT DEFINED BY ATOMS',&
          3i4) 
        if (icase == 2) then 
          if (abs(z0) < 0.0001D0) then 
            write (iw, 60) n1, n2, n3, n1, n2 
          else 
            write (iw, 70) n1, n2, n3, n1, n2, z0 
          endif 
        endif 
   60   format('line buggy') 
   70   format(1x,'Line buggy') 
        if (icase == 3) then 
          if (abs(z0) < 0.0001D0) then 
            write (iw, 80) n2, n1, n3 
          else 
            write (iw, 90) n2, n1, n3, z0 
          endif 
        endif 
   80   format(1x,'MEPS ARE IN THE PLANE BISECTING THE ANGLE (',3i3,')') 
   90   format(1x,'MEPS ARE IN THE PLANE BISECTING THE ANGLE (',3i3,')',/,5x,&
          'BUT NON-ZERO VALUE Z0=',f6.2,' MAKES NO SENSE',' AND IS IGNORED') 
      endif 
      if (icase <= 1) then 
        c1(1,:numat) = c(1,:numat) 
        c1(2,:numat) = c(2,:numat) 
        c1(3,:numat) = c(3,:numat) 
        go to 150 
      endif 
!                                            MOVE THE ORIGIN TO ATOM N1
      c1(1,:numat) = c(1,:numat) - c(1,n1) 
      c1(2,:numat) = c(2,:numat) - c(2,n1) 
      c1(3,:numat) = c(3,:numat) - c(3,n1) 
!
      x2 = c1(1,n2) 
      y2 = c1(2,n2) 
      z2 = c1(3,n2) 
      rr2 = x2*x2 + y2*y2 + z2*z2 
      r2 = dsqrt(rr2) 
      r21 = 1.0D0/r2 
      x3 = c1(1,n3) 
      y3 = c1(2,n3) 
      z3 = c1(3,n3) 
      rr3 = x3*x3 + y3*y3 + z3*z3 
      r3 = dsqrt(rr3) 
      r31 = 1.0D0/r3 
      cos1 = (rr3 + rr2 - (x3 - x2)**2 - (y3 - y2)**2 - (z3 - z2)**2)*(0.5D0*&
        r31*r21) 
      if (1.0D0 - dabs(cos1) < 0.01D0) then 
        write (6, 190) dacos(cos1) 
        call mopend ('Error in PMEP') 
        return  
      endif 
!
      if (icase==1 .or. icase==2) then 
!                                            CHOOSE X-AXIS FOR CASE 1,2
        t(1,1) = x2*r21 
        t(1,2) = y2*r21 
        t(1,3) = z2*r21 
!                                           Y-AXIS FOR CASE 1, Z CASE 2
        p41 = r3*cos1*r21 
        x34 = x3 - p41*x2 
        y34 = y3 - p41*y2 
        z34 = z3 - p41*z2 
        r341 = 1.0D0/dsqrt(x34*x34 + y34*y34 + z34*z34) 
        if (icase == 1) then 
          t(2,1) = x34*r341 
          t(2,2) = y34*r341 
          t(2,3) = z34*r341 
        else 
          t(3,1) = -x34*r341 
          t(3,2) = -y34*r341 
          t(3,3) = -z34*r341 
        endif 
      endif 
!                                           CHOOSE X, Z-AXES FOR CASE 3
      if (icase == 3) then 
        if (r3 > r2) then 
          x6 = r2*r31 
          y6 = x6*y3 
          z6 = x6*z3 
          x6 = x6*x3 
          x62 = x6 - x2 
          y62 = y6 - y2 
          z62 = z6 - z2 
          r621 = 1.0D0/dsqrt(x62*x62 + y62*y62 + z62*z62) 
          t(3,1) = -x62*r621 
          t(3,2) = -y62*r621 
          t(3,3) = -z62*r621 
          x4 = (x2 + x6)*0.5D0 
          y4 = (y2 + y6)*0.5D0 
          z4 = (z2 + z6)*0.5D0 
        else 
          x6 = r3*r21 
          y6 = x6*y2 
          z6 = x6*z3 
          x6 = x6*x2 
          x63 = x6 - x3 
          y63 = y6 - y3 
          z63 = z6 - z3 
          r631 = 1.0D0/dsqrt(x63*x63 + y63*y63 + z63*z63) 
          t(3,1) = x63*r631 
          t(3,2) = y63*r631 
          t(3,3) = z63*r631 
          x4 = (x3 + x6)*0.5D0 
          y4 = (y3 + y6)*0.5D0 
          z4 = (z3 + z6)*0.5D0 
        endif 
        r41 = 1.0D0/dsqrt(x4*x4 + y4*y4 + z4*z4) 
        t(1,1) = x4*r41 
        t(1,2) = y4*r41 
        t(1,3) = z4*r41 
      endif 
!                                      Z FOR ICASE=1, Y FOR ICASE=2 & 3
      z5 = 1.0D0 
      if (dabs(x2) > 0.1D0) then 
        y5 = -(x2*z3 - x3*z2)/(x2*y3 - x3*y2) 
        x5 = -(y5*y2 + z2)/x2 
        go to 130 
      endif 
      if (dabs(x3) > 0.1D0) then 
        y5 = -(x3*z2 - x2*z3)/(x3*y2 - x2*y3) 
        x5 = -(y3*y5 + z3)/x3 
        go to 130 
      endif 
      if (dabs(y3) > 0.1D0) then 
        x5 = -(y3*z2 - y2*z3)/(x2*y3 - x3*y2) 
        y5 = -(x5*x3 + z3)/y3 
        go to 130 
      endif 
      if (dabs(y2) > 0.1D0) then 
        x5 = -(y2*z3 - y3*z2)/(x3*y2 - x2*y3) 
        y5 = -(x5*x2 + z2)/y2 
        go to 130 
      else 
        write (iw, 200) x2, y2, x3, y3 
        call mopend ('Error in PMEP') 
        return  
      endif 
  130 continue 
      r51 = 1.0D0/dsqrt(x5*x5 + y5*y5 + 1.0D0) 
      k = 3 
      if (icase /= 1) k = 2 
      t(k,1) = x5*r51 
      t(k,2) = y5*r51 
      t(k,3) = z5*r51 
!                            ROTATE THE MOLECULE TO NEW XYZ COORDINATES
      do k = 1, numat 
        xi = t(1,1)*c1(1,k) + t(1,2)*c1(2,k) + t(1,3)*c1(3,k) 
        yi = t(2,1)*c1(1,k) + t(2,2)*c1(2,k) + t(2,3)*c1(3,k) 
        c1(3,k) = t(3,1)*c1(1,k) + t(3,2)*c1(2,k) + t(3,3)*c1(3,k) 
        c1(1,k) = xi 
        c1(2,k) = yi 
      end do 
!                                                   NON-WEIGHTED CENTER
  150 continue 
      do j = 1, 2 
        cs = 1.D6 
        cl = -1.D6 
        do i = 1, numat 
          if (c1(j,i) < cs) then 
            cs = c1(j,i) 
            is = i 
          endif 
          if (c1(j,i) <= cl) cycle  
          cl = c1(j,i) 
          il = i 
        end do 
        c0(j) = (cs + cl)/2.0D0 
        r0(j) = cl - c0(j) + 2.0D0 
        if (nat(is)<=1 .and. nat(il)<=1) cycle  
        r0(j) = r0(j) + 0.4D0 
      end do 
!                                                MOVE TO THE NEW CENTER
      c1(1,:numat) = c1(1,:numat) - c0(1) 
      c1(2,:numat) = c1(2,:numat) - c0(2) 
      xm = int(r0(1)/step)*step 
      ym = int(r0(2)/step)*step 
      if (icase<1 .or. icase>3) then 
        r0(1) = ((-xm) + c0(1))*t(1,1) + ((-ym) + c0(2))*t(2,1) 
        r0(2) = ((-xm) + c0(1))*t(1,2) + ((-ym) + c0(2))*t(2,2) 
        r0(3) = ((-xm) + c0(1))*t(1,3) + ((-ym) + c0(2))*t(2,3) 
      else 
        if (icase == 1) then 
          r0(1) = ((-xm) + c0(1))*t(1,1) + ((-ym) + c0(2))*t(2,1) + c(1,n1) 
          r0(2) = ((-xm) + c0(1))*t(1,2) + ((-ym) + c0(2))*t(2,2) + c(2,n1) 
          r0(3) = ((-xm) + c0(1))*t(1,3) + ((-ym) + c0(2))*t(2,3) + c(3,n1) 
        else 
          r0(1) = ((-xm) + c0(1))*t(1,1) + c0(2)*t(2,1) + c(1,n1) 
          r0(2) = ((-xm) + c0(1))*t(1,2) + c0(2)*t(2,2) + c(2,n1) 
          r0(3) = ((-xm) + c0(1))*t(1,3) + c0(2)*t(2,3) + c(3,n1) 
        endif 
      endif 
      return  
  190 format(1x,'N2-N1-N3=',f9.3,' DEGREES, ALMOST LINEAR!') 
  200 format('X21,Y21,X31,Y31=',4f8.4,' WHY THEY ARE SO SMALL?')  
      end subroutine meprot 


!
      subroutine packp(p, pp, mn) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      use molkst_C, only : numat
      use permanent_arrays, only : nfirst, nlast
!*********************************************************************
!  SUBROUTINE PACKP RE-WRITES THE DENSITY MATRIX.
!  WRITTEN BY BINGZE WANG, 20 OCTOBER 1991.
!*********************************************************************
!***********************************************************************
!DECK MOPAC
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:03:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
      implicit none
!-----------------------------------------------
!   G l o b a l   P a r a m e t e r s
!-----------------------------------------------
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(out) :: mn 
      real(double) , intent(in) :: p(*) 
      real(double) , intent(out) :: pp(*) 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer :: i, ia, ib, j, j1st
!-----------------------------------------------
      mn = 0 
      do i = 1, numat 
        ia = nfirst(i) 
        ib = nlast(i) 
        do j = ia, ib 
          j1st = j*(j - 1)/2 
          if (j - ia + 1 > 0) then 
            pp(mn+1:j-ia+1+mn) = p(j1st+ia:j+j1st) 
            mn = j - ia + 1 + mn 
          endif 
        end do 
      end do 
      return  
      end subroutine packp 
