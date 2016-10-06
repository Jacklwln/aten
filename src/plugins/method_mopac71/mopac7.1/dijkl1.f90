      subroutine dijkl1(c, n, nati, w, cij, wcij, ckl, xy) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      use molkst_C, only : numat, norbs
      use permanent_arrays, only : nfirst, nlast
      use meci_C, only : nmos
!***********************************************************************
!DECK MOPAC
!...Translated by Pacific-Sierra Research 77to90  4.4G  10:47:09  03/09/06  
!...Switches: -rl INDDO=2 INDIF=2 
!-----------------------------------------------
!   I n t e r f a c e   B l o c k s
!-----------------------------------------------
      use formxy_I 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(in) :: n 
      integer , intent(in) :: nati 
      real(double) , intent(in) :: c(n,*) 
      real(double)  :: w(*) 
      real(double)  :: cij(10*norbs) 
      real(double)  :: wcij(10*norbs) 
      real(double) , intent(inout) :: ckl(10*norbs) 
      real(double) , intent(out) :: xy(nmos,nmos,nmos,nmos) 
!-----------------------------------------------
!   L o c a l   P a r a m e t e r s
!-----------------------------------------------
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer , dimension(0:8) :: nb 
      integer :: na, i, j, ipq, ii, ip, i77, kr, js, nbj, nbi, k, ll, l 
      real(double) :: sum 

      save nb 
!-----------------------------------------------
!***********************************************************************
!
!   DIJKL1 IS SIMILAR TO IJKL.  THE MAIN DIFFERENCES ARE THAT
!   THE ARRAY W CONTAINS THE TWO ELECTRON INTEGRALS BETWEEN
!   ONE ATOM (NATI) AND ALL THE OTHER ATOMS IN THE SYSTEM.
!
!           ON EXIT
!
!   THE ARRAY XY IS FILLED WITH THE DIFFERENTIALS OF THE
!   TWO-ELECTRON INTEGRALS OVER ACTIVE-SPACE M.O.S W.R.T. MOTION
!   OF THE ATOM NATI.
!***********************************************************************
      data nb/ 1, 0, 0, 10, 0, 0, 0, 0, 45/  
      na = nmos 
      do i = 1, na 
        do j = 1, i 
          ipq = 0 
          do ii = 1, numat 
            if (ii == nati) cycle  
            do ip = nfirst(ii), nlast(ii) 
              if (ip - nfirst(ii) + 1 > 0) then 
                cij(ipq+1:ip-nfirst(ii)+1+ipq) = c(ip,i)*c(nfirst(ii):ip,j) + c&
                  (ip,j)*c(nfirst(ii):ip,i) 
                ipq = ip - nfirst(ii) + 1 + ipq 
              endif 
            end do 
          end do 
          i77 = ipq + 1 
          do ip = nfirst(nati), nlast(nati) 
            if (ip - nfirst(nati) + 1 > 0) then 
              cij(ipq+1:ip-nfirst(nati)+1+ipq) = c(ip,i)*c(nfirst(nati):ip,j)&
                 + c(ip,j)*c(nfirst(nati):ip,i) 
              ipq = ip - nfirst(nati) + 1 + ipq 
            endif 
          end do 
          wcij(:ipq) = 0.D0 
          kr = 1 
          js = 1 
          nbj = nlast(nati) - nfirst(nati) 
          if (nbj >= 0) then 
            nbj = nb(nbj) 
            do ii = 1, numat 
              if (ii == nati) cycle  
              nbi = nlast(ii) - nfirst(ii) 
              if (nbi < 0) cycle  
              nbi = nb(nbi) 
              call formxy (w(kr), kr, wcij(i77), wcij(js), cij(i77), nbj, cij(&
                js), nbi) 
              js = js + nbi 
            end do 
          endif 
          do k = 1, i 
            if (k == i) then 
              ll = j 
            else 
              ll = k 
            endif 
            do l = 1, ll 
              ipq = 0 
              do ii = 1, numat 
                if (ii == nati) cycle  
                do ip = nfirst(ii), nlast(ii) 
                  if (ip - nfirst(ii) + 1 > 0) then 
                    ckl(ipq+1:ip-nfirst(ii)+1+ipq) = c(ip,k)*c(nfirst(ii):ip,l)&
                       + c(ip,l)*c(nfirst(ii):ip,k) 
                    ipq = ip - nfirst(ii) + 1 + ipq 
                  endif 
                end do 
              end do 
              do ip = nfirst(nati), nlast(nati) 
                if (ip - nfirst(nati) + 1 > 0) then 
                  ckl(ipq+1:ip-nfirst(nati)+1+ipq) = c(ip,k)*c(nfirst(nati):ip,&
                    l) + c(ip,l)*c(nfirst(nati):ip,k) 
                  ipq = ip - nfirst(nati) + 1 + ipq 
                endif 
              end do 
              sum = 0.D0 
              do ii = 1, ipq 
                sum = sum + ckl(ii)*wcij(ii) 
              end do 
              xy(i,j,k,l) = sum 
              xy(i,j,l,k) = sum 
              xy(j,i,k,l) = sum 
              xy(j,i,l,k) = sum 
              xy(k,l,i,j) = sum 
              xy(k,l,j,i) = sum 
              xy(l,k,i,j) = sum 
              xy(l,k,j,i) = sum 
            end do 
          end do 
        end do 
      end do 
      return  
      end subroutine dijkl1 
