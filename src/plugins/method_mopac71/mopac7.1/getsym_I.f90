
      MODULE getsym_I   
      INTERFACE
!...Generated by Pacific-Sierra Research 77to90  4.4G  10:47:17  03/09/06  
      subroutine getsym (locpar, idepfn, locdep, depmul)
      use molkst_C, only: natoms, ndep
      implicit none
      integer, dimension (3*natoms), intent (inout) :: idepfn, locpar
      integer, dimension (3*natoms), intent (out) :: locdep
      double precision, dimension (natoms), intent (out) :: depmul
      END SUBROUTINE  
      END INTERFACE 
      END MODULE 
