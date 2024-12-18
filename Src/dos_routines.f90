!  ShengBTE, a solver for the Boltzmann Transport Equation for phonons
!  Copyright (C) 2012-2015 Wu Li <wu.li.phys2011@gmail.com>
!  Copyright (C) 2012-2015 Jesús Carrete Montaña <jcarrete@gmail.com>
!  Copyright (C) 2012-2015 Nebil Ayape Katcho <nebil.ayapekatcho@cea.fr>
!  Copyright (C) 2012-2015 Natalio Mingo Bisquert <natalio.mingo@cea.fr>
!
!  This program is free software: you can redistribute it and/or modify
!  it under the terms of the GNU General Public License as published by
!  the Free Software Foundation, either version 3 of the License, or
!  (at your option) any later version.
!
!  This program is distributed in the hope that it will be useful,
!  but WITHOUT ANY WARRANTY; without even the implied warranty of
!  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!  GNU General Public License for more details.
!
!  You should have received a copy of the GNU General Public License
!  along with this program.  If not, see <http://www.gnu.org/licenses/>.

! Routines to calculate the density of states and related quantities.
module dos_routines
  use config
  implicit none

contains

  ! Compute a first estimate of the broadening for each mode.
  subroutine calc_sigma0(velocity,sigma)
    implicit none

    real(kind=8),intent(in) :: velocity(nptk,nbands,3)
    real(kind=8),intent(out) :: sigma(nptk,nbands)

    integer(kind=4) :: ii,jj

    do ii=1,nptk
       do jj=1,nbands
          sigma(ii,jj)=base_sigma(velocity(ii,jj,:))
       end do
    end do
  end subroutine calc_sigma0

  ! Compute the 25th and 75th percentiles of log(sigma)
  subroutine calc_percentiles(sigma,per25,per75)
    implicit none

    real(kind=8),intent(in) :: sigma(nptk,nbands)
    real(kind=8),intent(out) :: per25,per75

    integer(kind=4) :: ii,jj,pos
    real(kind=8) :: logsigma(nptk*nbands)

    do ii=1,nptk
       do jj=1,nbands
          pos=(ii-1)*nbands+jj
          if(sigma(ii,jj)==0.d0) then
             logsigma(pos)=-huge(logsigma)
          else
             logsigma(pos)=log(sigma(ii,jj))
          end if
       end do
    end do

    call dlasrt("I",nptk*nbands,logsigma,ii)
    per25=logsigma(25*nptk*nbands/100)
    per75=logsigma(75*nptk*nbands/100)
  end subroutine calc_percentiles

  ! Refine the initial estimate of smearing to avoid huge
  ! peaks in the DOS.
  subroutine refine_sigma(sigma)
    implicit none

    real(kind=8),intent(inout) :: sigma(nptk,nbands)

    real(kind=8) :: per25,per75,delta,lbound

    call calc_percentiles(sigma,per25,per75)
    delta=per75-per25
    lbound=exp(per25-1.5*delta)
    sigma=max(sigma,lbound)
  end subroutine refine_sigma

  ! Compute the DOS, the projected DOS and the isotopic scattering rates.
  subroutine calc_dos(omega,velocity,eigenvect,nlist,list,&
       dos,pdos,rate_scatt_isotope)
    implicit none
    include "mpif.h" !modify zxy
    real(kind=8),intent(in) :: omega(nptk,nbands)
    real(kind=8),intent(in) :: velocity(nptk,nbands,3)
    complex(kind=8),intent(in) :: eigenvect(nptk,nbands,nbands)
    integer(kind=4),intent(in) :: nlist
    integer(kind=4),intent(in) :: list(nptk)
    
    real(kind=8),intent(out) :: dos(nbands,nlist)
    real(kind=8),intent(out) :: pdos(nbands,nlist,natoms)
    real(kind=8),intent(out) :: rate_scatt_isotope(nbands,nlist)

    integer(kind=4) :: ii,jj,kk,mm,nn
    real(kind=8) :: sigma(nptk,nbands),thisomega,thissigma,weight,prod
!modify zxy
integer(kind=4) :: mm_zxy
real(kind=8) :: dos_zxy(nbands,nlist),pdos_zxy(nbands,nlist,natoms), rate_scatt_isotope_zxy(nbands,nlist)
!modify zxy
    call calc_sigma0(velocity,sigma)
    call refine_sigma(sigma)
    
    dos=0.d0
    pdos=0.d0
    rate_scatt_isotope=0.d0
    dos_zxy=0.d0
    pdos_zxy=0.d0
    rate_scatt_isotope_zxy=0.d0
    do mm_zxy=myid+1,Nbands*Nlist,numprocs    !modify zxy
       nn=modulo(mm_zxy-1,Nbands)+1
       mm=int((mm_zxy-1)/Nbands)+1
   !    write(*,*) 'myid, numprocs,mm_zxy,mm,nn',myid,numprocs,mm_zxy,mm,nn
   !zxy do mm=1,Nlist
   !zxy    do nn=1,Nbands
          thisomega=omega(list(mm),nn)
          if(thisomega==0.) then
             cycle
          end if
          do ii=1,nptk
             do jj=1,Nbands
                thissigma=sigma(ii,jj)
                weight=exp(-(thisomega-omega(ii,jj))**2/(thissigma**2))&
                     /thissigma/sqrt(pi)
                if(abs(thisomega-omega(ii,jj)).lt.2.5*thissigma) then
                   dos_zxy(nn,mm)=dos_zxy(nn,mm)+weight
                   do kk=1,natoms
                      prod=(abs(dot_product(&
                           eigenvect(list(mm),nn,((kk-1)*3+1):((kk-1)*3+3)),&
                           eigenvect(ii,jj,((kk-1)*3+1):((kk-1)*3+3)))))**2
                      pdos_zxy(nn,mm,kk)=pdos_zxy(nn,mm,kk)+weight*prod
                      if(isotopes) then
                         rate_scatt_isotope_zxy(nn,mm)=rate_scatt_isotope_zxy(nn,mm)+&
                              weight*prod*gfactors(types(kk))
                      end if
                   end do
                end if
             end do
          end do
          if(isotopes) then
             rate_scatt_isotope_zxy(nn,mm)=rate_scatt_isotope_zxy(nn,mm)/&
                  (2.d0*nptk)*pi*thisomega**2
          end if
   !zxy    end do
   !zxy end do
        end do !modify zxy
       !modify zxy
        call MPI_ALLREDUCE(dos_zxy,dos,nbands*nlist,MPI_DOUBLE_PRECISION,&
         MPI_SUM,MPI_COMM_WORLD,mm_zxy)
        call MPI_ALLREDUCE(pdos_zxy,pdos,nbands*nlist,MPI_DOUBLE_PRECISION,&
         MPI_SUM,MPI_COMM_WORLD,mm_zxy)
        call MPI_ALLREDUCE(rate_scatt_isotope_zxy,rate_scatt_isotope,nbands*nlist,MPI_DOUBLE_PRECISION,&
         MPI_SUM,MPI_COMM_WORLD,mm_zxy)
        !modify zxy
    dos=dos/float(nptk)
    pdos=pdos/float(nptk)
  end subroutine calc_dos

end module dos_routines
