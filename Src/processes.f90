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

! Compute the number of allowed three-phonon processes, their
! scattering amplitudes and their phase-space volume.

module processes
  use iso_fortran_env
  use misc
  use data
  use config
  implicit none

  real(kind=8),parameter :: hbarp=hbar*1e22

contains
!real(8) :: random_real_matrix(Nbands*Nbands*nptk)!modify zxy
!integer :: random_integer_matrix(!modify zxy
  ! Compute one of the matrix elements involved in the calculation of Ind_plus.
  function Vp_plus(i,j,k,q,qprime,qdprime,realqprime,realqdprime,eigenvect,&
       Ntri,Phi,R_j,R_k,Index_i,Index_j,Index_k)
    implicit none

    integer(kind=4),intent(in) :: i
    integer(kind=4),intent(in) :: j
    integer(kind=4),intent(in) :: k
    integer(kind=4),intent(in) :: q
    integer(kind=4),intent(in) :: qprime
    integer(kind=4),intent(in) :: qdprime
    real(kind=8),intent(in) :: realqprime(3)
    real(kind=8),intent(in) :: realqdprime(3)    
    complex(kind=8),intent(in) :: eigenvect(nptk,Nbands,Nbands)
    integer(kind=4),intent(in) :: Ntri
    real(kind=8),intent(in) :: Phi(3,3,3,Ntri)
    real(kind=8),intent(in) :: R_j(3,Ntri)
    real(kind=8),intent(in) :: R_k(3,Ntri)
    integer(kind=4),intent(in) :: Index_i(Ntri)
    integer(kind=4),intent(in) :: Index_j(Ntri)
    integer(kind=4),intent(in) :: Index_k(Ntri)

    complex(kind=8) :: Vp_plus

    integer(kind=4) :: ll
    integer(kind=4) :: rr
    integer(kind=4) :: ss
    integer(kind=4) :: tt
    complex(kind=8) :: prefactor
    complex(kind=8) :: Vp0

    Vp_plus=0.d0
    
    do ll=1,Ntri
       prefactor=1.d0/sqrt(masses(types(Index_i(ll)))*&
            masses(types(Index_j(ll)))*masses(types(Index_k(ll))))*&
            phexp(dot_product(realqprime/ngrid,R_j(:,ll)))*&
            phexp(-dot_product(realqdprime/ngrid,R_k(:,ll)))
       Vp0=0.d0
       do rr=1,3
          do ss=1,3
             do tt=1,3
                Vp0=Vp0+Phi(tt,ss,rr,ll)*&
                     eigenvect(q,i,tt+3*(Index_i(ll)-1))*&
                     eigenvect(qprime,j,ss+3*(Index_j(ll)-1))*&
                     conjg(eigenvect(qdprime,k,rr+3*(Index_k(ll)-1)))
             end do
          end do
       end do
       Vp_plus=Vp_plus+prefactor*Vp0
    end do
  end function Vp_plus

  ! Compute one of the matrix elements involved in the calculation of Ind_minus.
  function Vp_minus(i,j,k,q,qprime,qdprime,realqprime,realqdprime,eigenvect,&
       Ntri,Phi,R_j,R_k,Index_i,Index_j,Index_k)
    implicit none

    integer(kind=4),intent(in) :: i
    integer(kind=4),intent(in) :: j
    integer(kind=4),intent(in) :: k
    integer(kind=4),intent(in) :: q
    integer(kind=4),intent(in) :: qprime
    integer(kind=4),intent(in) :: qdprime
    real(kind=8),intent(in) :: realqprime(3)
    real(kind=8),intent(in) :: realqdprime(3)    
    complex(kind=8),intent(in) :: eigenvect(nptk,Nbands,Nbands)
    integer(kind=4),intent(in) :: Ntri
    real(kind=8),intent(in) :: Phi(3,3,3,Ntri)
    real(kind=8),intent(in) :: R_j(3,Ntri)
    real(kind=8),intent(in) :: R_k(3,Ntri)
    integer(kind=4),intent(in) :: Index_i(Ntri)
    integer(kind=4),intent(in) :: Index_j(Ntri)
    integer(kind=4),intent(in) :: Index_k(Ntri)

    complex(kind=8) :: Vp_minus

    integer(kind=4) :: ll
    integer(kind=4) :: rr
    integer(kind=4) :: ss
    integer(kind=4) :: tt
    complex(kind=8) :: prefactor
    complex(kind=8) :: Vp0

    Vp_minus=0.d0

    do ll=1,Ntri
       prefactor=1.d0/sqrt(masses(types(Index_i(ll)))*&
            masses(types(Index_j(ll)))*masses(types(Index_k(ll))))*&
            phexp(-dot_product(realqprime/ngrid,R_j(:,ll)))*&
            phexp(-dot_product(realqdprime/ngrid,R_k(:,ll)))
       Vp0=0.
       do rr=1,3
          do ss=1,3
             do tt=1,3
                Vp0=Vp0+Phi(tt,ss,rr,ll)*&
                     eigenvect(q,i,tt+3*(Index_i(ll)-1))*&
                     conjg(eigenvect(qprime,j,ss+3*(Index_j(ll)-1)))*&
                     conjg(eigenvect(qdprime,k,rr+3*(Index_k(ll)-1)))
             end do
          end do
       end do
       Vp_minus=Vp_minus+prefactor*Vp0
    end do
  end function Vp_minus

  ! Scattering amplitudes of absorption processes.
  subroutine Ind_plus(mm,N_plus,energy,velocity,eigenvect,Nlist,List,&
       Ntri,Phi,R_j,R_k,Index_i,Index_j,Index_k,IJK,&
       Indof2ndPhonon_plus,Indof3rdPhonon_plus,Gamma_plus)
    implicit none

    integer(kind=4),intent(in) :: mm,NList,List(Nlist),IJK(3,nptk),N_plus,Ntri
    integer(kind=4),intent(in) :: Index_i(Ntri),Index_j(Ntri),Index_k(Ntri)
    real(kind=8),intent(in) :: energy(nptk,Nbands),velocity(nptk,Nbands,3)
    real(kind=8),intent(in) :: Phi(3,3,3,Ntri),R_j(3,Ntri),R_k(3,Ntri)
    complex(kind=8),intent(in) :: eigenvect(nptk,Nbands,Nbands)
    integer(kind=4),intent(out) :: Indof2ndPhonon_plus(N_plus),Indof3rdPhonon_plus(N_plus)
    real(kind=8),intent(out) :: Gamma_plus(N_plus)

    integer(kind=4) :: q(3),qprime(3),qdprime(3),i,j,k,N_plus_count
    integer(kind=4) :: Index_N(0:(Ngrid(1)-1),0:(Ngrid(2)-1),0:(Ngrid(3)-1))
    integer(kind=4) :: ii,jj,kk,ll,ss
    real(kind=8) :: sigma
    real(kind=8) :: fBEprime,fBEdprime
    real(kind=8) :: omega,omegap,omegadp
    real(kind=8) :: realqprime(3),realqdprime(3)
    complex(kind=8) :: Vp

    do ii=0,Ngrid(1)-1        ! G1 direction
       do jj=0,Ngrid(2)-1     ! G2 direction
          do kk=0,Ngrid(3)-1  ! G3 direction
             Index_N(ii,jj,kk)=(kk*Ngrid(2)+jj)*Ngrid(1)+ii+1
          end do
       end do
    end do
    N_plus_count=0
    i=modulo(mm-1,Nbands)+1
    ll=int((mm-1)/Nbands)+1
    q=IJK(:,list(ll))
    omega=energy(list(ll),i)
    ! Loop over all processes, detecting those that are allowed and
    ! computing their amplitudes.
    if(omega.ne.0) then
       do j=1,Nbands
          do ii=1,nptk
             qprime=IJK(:,ii)
             realqprime=matmul(rlattvec,qprime)
             omegap=energy(ii,j)
             fBEprime=1.d0/(exp(hbar*omegap/Kb/T)-1.D0)
             !--------BEGIN absorption process-----------
             do k=1,Nbands
                qdprime=q+qprime
                qdprime=modulo(qdprime,Ngrid)
                realqdprime=matmul(rlattvec,qdprime)
                ss=Index_N(qdprime(1),qdprime(2),qdprime(3))
                omegadp=energy(ss,k)
                if ((omegap.ne.0).and.(omegadp.ne.0)) then
                   sigma=scalebroad*base_sigma(&
                        velocity(ii,j,:)-&
                        velocity(ss,k,:))
                   if(abs(omega+omegap-omegadp).le.(2.d0*sigma)) then
                      N_plus_count=N_plus_count+1
                      Indof2ndPhonon_plus(N_plus_count)=(ii-1)*Nbands+j
                      Indof3rdPhonon_plus(N_plus_count)=(ss-1)*Nbands+k
                      fBEdprime=1.d0/(exp(hbar*omegadp/Kb/T)-1.D0)
                      Vp=Vp_plus(i,j,k,list(ll),ii,ss,&
                           realqprime,realqdprime,eigenvect,&
                           Ntri,Phi,R_j,R_k,Index_i,Index_j,Index_k)
                      Gamma_plus(N_plus_count)=hbarp*pi/4.d0*(fBEprime-fBEdprime)*&
                           exp(-(omega+omegap-omegadp)**2/(sigma**2))/sigma/sqrt(Pi)/&
                           (omega*omegap*omegadp)*abs(Vp)**2
                      ! At this point, Gamma's units are
                      ! (1.d-34J*s)*(1.d12/s)^(-4)*1amu^(-3)*(ev/angstrom**3)^2,
                      ! that is, 5.60626442*1.d8 THz
                      Gamma_plus(N_plus_count)=Gamma_plus(N_plus_count)*5.60626442*1.d8/nptk ! THz
                   end if
                end if
             end do ! k
             !--------END absorption process-------------!
          end do ! ii
       end do  ! j
    end if
  end subroutine Ind_plus

  ! Scattering amplitudes of emission processes. See Ind_plus() for details.
  subroutine Ind_minus(mm,N_minus,energy,velocity,eigenvect,Nlist,List,&
       Ntri,Phi,R_j,R_k,Index_i,Index_j,Index_k,IJK,&
       Indof2ndPhonon_minus,Indof3rdPhonon_minus,Gamma_minus)
    implicit none

    integer(kind=4),intent(in) :: mm,NList,List(Nlist),IJK(3,nptk),N_minus,Ntri
    integer(kind=4),intent(in) :: Index_i(Ntri),Index_j(Ntri),Index_k(Ntri)
    real(kind=8),intent(in) :: energy(nptk,Nbands),velocity(nptk,Nbands,3)
    real(kind=8),intent(in) :: Phi(3,3,3,Ntri),R_j(3,Ntri),R_k(3,Ntri)
    complex(kind=8),intent(in) :: eigenvect(nptk,Nbands,Nbands)
    integer(kind=4),intent(out) :: Indof2ndPhonon_minus(N_minus),Indof3rdPhonon_minus(N_minus)
    real(kind=8),intent(out) :: Gamma_minus(N_minus)

    integer(kind=4) :: q(3),qprime(3),qdprime(3),i,j,k,N_minus_count
    integer(kind=4) :: Index_N(0:(Ngrid(1)-1),0:(Ngrid(2)-1),0:(Ngrid(3)-1))
    integer(kind=4) :: ii,jj,kk,ll,ss
    real(kind=8) :: sigma
    real(kind=8) :: fBEprime,fBEdprime
    real(kind=8) ::  omega,omegap,omegadp
    real(kind=8) :: realqprime(3),realqdprime(3)
    complex(kind=8) :: Vp

    do ii=0,Ngrid(1)-1        ! G1 direction
       do jj=0,Ngrid(2)-1     ! G2 direction
          do kk=0,Ngrid(3)-1  ! G3 direction
             Index_N(ii,jj,kk)=(kk*Ngrid(2)+jj)*Ngrid(1)+ii+1
          end do
       end do
    end do
    N_minus_count=0
    i=modulo(mm-1,Nbands)+1
    ll=int((mm-1)/Nbands)+1
    q=IJK(:,list(ll))
    omega=energy(list(ll),i)
    if(omega.ne.0) then
       do j=1,Nbands
          do ii=1,nptk
             qprime=IJK(:,ii)
             realqprime=matmul(rlattvec,qprime)
             omegap=energy(ii,j)
             fBEprime=1.d0/(exp(hbar*omegap/Kb/T)-1.D0)
             !--------BEGIN emission process-----------
             do k=1,Nbands
                qdprime=q-qprime
                qdprime=modulo(qdprime,Ngrid)
                realqdprime=matmul(rlattvec,qdprime)
                ss=Index_N(qdprime(1),qdprime(2),qdprime(3))
                omegadp=energy(ss,k)
                if ((omegap.ne.0).and.(omegadp.ne.0)) then
                   sigma=scalebroad*base_sigma(&
                        velocity(ii,j,:)-&
                        velocity(ss,k,:))
                   if (abs(omega-omegap-omegadp).le.(2.d0*sigma)) then
                      N_minus_count=N_minus_count+1
                      Indof2ndPhonon_minus(N_minus_count)=(ii-1)*Nbands+j
                      Indof3rdPhonon_minus(N_minus_count)=(ss-1)*Nbands+k
                      fBEdprime=1.d0/(exp(hbar*omegadp/Kb/T)-1.D0)
                      Vp=Vp_minus(i,j,k,list(ll),ii,ss,&
                           realqprime,realqdprime,eigenvect,&
                           Ntri,Phi,R_j,R_k,Index_i,Index_j,Index_k)
                      Gamma_minus(N_minus_count)=hbarp*pi/4.d0*(fBEprime+fBEdprime+1)*&
                           exp(-(omega-omegap-omegadp)**2/(sigma**2))/sigma/sqrt(Pi)/&
                           (omega*omegap*omegadp)*abs(Vp)**2
                      Gamma_minus(N_minus_count)=Gamma_minus(N_minus_count)*5.60626442*1.d8/nptk
                   end if
                end if
             end do ! k
             !--------END emission process-------------
          end do ! ii
       end do  ! j
    end if
  end subroutine Ind_minus

  ! Wrapper around Ind_plus and Ind_minus that splits the work among processors.
  subroutine Ind_driver(energy,velocity,eigenvect,Nlist,List,IJK,N_plus,N_minus,&
       Ntri,Phi,R_j,R_k,Index_i,Index_j,Index_k,&
       Indof2ndPhonon_plus,Indof3rdPhonon_plus,Gamma_plus,&
       Indof2ndPhonon_minus,Indof3rdPhonon_minus,Gamma_minus,rate_scatt)
    implicit none

    include "mpif.h"

    real(kind=8),intent(in) :: energy(nptk,nbands)
    real(kind=8),intent(in) :: velocity(nptk,nbands,3)
    complex(kind=8),intent(in) :: eigenvect(nptk,Nbands,Nbands)
    integer(kind=4),intent(in) :: NList
    integer(kind=4),intent(in) :: List(Nlist)
    integer(kind=4),intent(in) :: IJK(3,nptk)
    integer(kind=4),intent(in) :: N_plus(Nlist*Nbands)
    integer(kind=4),intent(in) :: N_minus(Nlist*Nbands)
    integer(kind=4),intent(in) :: Ntri
    real(kind=8),intent(in) :: Phi(3,3,3,Ntri)
    real(kind=8),intent(in) :: R_j(3,Ntri)
    real(kind=8),intent(in) :: R_k(3,Ntri)
    integer(kind=4),intent(in) :: Index_i(Ntri)
    integer(kind=4),intent(in) :: Index_j(Ntri)
    integer(kind=4),intent(in) :: Index_k(Ntri)
    integer(kind=4),intent(out) :: Indof2ndPhonon_plus(:)
    integer(kind=4),intent(out) :: Indof3rdPhonon_plus(:)
    real(kind=8),intent(out) :: Gamma_plus(:)
    integer(kind=4),intent(out) :: Indof2ndPhonon_minus(:)
    integer(kind=4),intent(out) :: Indof3rdPhonon_minus(:)
    real(kind=8),intent(out) :: Gamma_minus(:)
    real(kind=8),intent(out) :: rate_scatt(Nbands,Nlist)

    integer(kind=4) :: i
    integer(kind=4) :: ll
    integer(kind=4) :: mm
    integer(kind=4) :: maxsize
    integer(kind=4) :: Ntotal_plus
    integer(kind=4) :: Ntotal_minus
    integer(kind=4) :: Naccum_plus(Nbands*Nlist)
    integer(kind=4) :: Naccum_minus(Nbands*Nlist)
    integer(kind=4),allocatable :: Indof2ndPhonon(:)
    integer(kind=4),allocatable :: Indof3rdPhonon(:)
    integer(kind=4),allocatable :: Indof2ndPhonon_plus_reduce(:)
    integer(kind=4),allocatable :: Indof3rdPhonon_plus_reduce(:)
    integer(kind=4),allocatable :: Indof2ndPhonon_minus_reduce(:)
    integer(kind=4),allocatable :: Indof3rdPhonon_minus_reduce(:)
    real(kind=8) :: rate_scatt_reduce(Nbands,Nlist)
    real(kind=8),allocatable :: Gamma0(:)
    real(kind=8),allocatable :: Gamma_plus_reduce(:)
    real(kind=8),allocatable :: Gamma_minus_reduce(:)

    maxsize=max(maxval(N_plus),maxval(N_minus))
    allocate(Indof2ndPhonon(maxsize))
    allocate(Indof3rdPhonon(maxsize))
    allocate(Gamma0(maxsize))

    Naccum_plus(1)=0
    Naccum_minus(1)=0
    do mm=2,Nbands*Nlist
       Naccum_plus(mm)=Naccum_plus(mm-1)+N_plus(mm-1)
       Naccum_minus(mm)=Naccum_minus(mm-1)+N_minus(mm-1)
    end do
    Ntotal_plus=sum(N_plus)
    Ntotal_minus=sum(N_minus)

    allocate(Indof2ndPhonon_plus_reduce(Ntotal_plus))
    allocate(Indof3rdPhonon_plus_reduce(Ntotal_plus))
    allocate(Indof2ndPhonon_minus_reduce(Ntotal_minus))
    allocate(Indof3rdPhonon_minus_reduce(Ntotal_minus))
    allocate(Gamma_plus_reduce(Ntotal_plus))
    allocate(Gamma_minus_reduce(Ntotal_minus))

    Indof2ndPhonon_plus_reduce=0
    Indof3rdPhonon_plus_reduce=0
    Indof2ndPhonon_minus_reduce=0
    Indof3rdPhonon_minus_reduce=0
    Gamma_plus_reduce=0.d0
    Gamma_minus_reduce=0.d0
    rate_scatt_reduce=0.d0

    do mm=myid+1,Nbands*NList,numprocs
       i=modulo(mm-1,Nbands)+1
       ll=int((mm-1)/Nbands)+1
       if(N_plus(mm).ne.0) then
          call Ind_plus(mm,N_plus(mm),energy,velocity,eigenvect,Nlist,List,&
               Ntri,Phi,R_j,R_k,Index_i,Index_j,Index_k,IJK,&
               Indof2ndPhonon(1:N_plus(mm)),Indof3rdPhonon(1:N_plus(mm)),&
               Gamma0(1:N_plus(mm)))
          Indof2ndPhonon_plus_reduce((Naccum_plus(mm)+1):(Naccum_plus(mm)+N_plus(mm)))=&
               Indof2ndPhonon(1:N_plus(mm))
          Indof3rdPhonon_plus_reduce((Naccum_plus(mm)+1):(Naccum_plus(mm)+N_plus(mm)))=&
               Indof3rdPhonon(1:N_plus(mm))
          Gamma_plus_reduce((Naccum_plus(mm)+1):(Naccum_plus(mm)+N_plus(mm)))=&
               Gamma0(1:N_plus(mm))
          rate_scatt_reduce(i,ll)=rate_scatt_reduce(i,ll)+sum(Gamma0(1:N_plus(mm)))
       end if
       if(N_minus(mm).ne.0) then
          call Ind_minus(mm,N_minus(mm),energy,velocity,eigenvect,Nlist,List,&
               Ntri,Phi,R_j,R_k,Index_i,Index_j,Index_k,IJK,&
               Indof2ndPhonon(1:N_minus(mm)),Indof3rdPhonon(1:N_minus(mm)),&
               Gamma0(1:N_minus(mm)))
          Indof2ndPhonon_minus_reduce((Naccum_minus(mm)+1):(Naccum_minus(mm)+N_minus(mm)))=&
               Indof2ndPhonon(1:N_minus(mm))
          Indof3rdPhonon_minus_reduce((Naccum_minus(mm)+1):(Naccum_minus(mm)+N_minus(mm)))=&
               Indof3rdPhonon(1:N_minus(mm))
          Gamma_minus_reduce((Naccum_minus(mm)+1):(Naccum_minus(mm)+N_minus(mm)))=&
               Gamma0(1:N_minus(mm))
          rate_scatt_reduce(i,ll)=rate_scatt_reduce(i,ll)+sum(Gamma0(1:N_minus(mm)))*5.D-1
       end if
    end do

    deallocate(Gamma0)
    deallocate(Indof3rdPhonon)
    deallocate(Indof2ndPhonon)

    call MPI_ALLREDUCE(Indof2ndPhonon_plus_reduce,Indof2ndPhonon_plus,&
         Ntotal_plus,MPI_INTEGER,MPI_SUM,MPI_COMM_WORLD,ll)
    call MPI_ALLREDUCE(Indof3rdPhonon_plus_reduce,Indof3rdPhonon_plus,&
         Ntotal_plus,MPI_INTEGER,MPI_SUM,MPI_COMM_WORLD,ll)
    call MPI_ALLREDUCE(Indof2ndPhonon_minus_reduce,Indof2ndPhonon_minus,&
         Ntotal_minus,MPI_INTEGER,MPI_SUM,MPI_COMM_WORLD,ll)
    call MPI_ALLREDUCE(Indof3rdPhonon_minus_reduce,Indof3rdPhonon_minus,&
         Ntotal_minus,MPI_INTEGER,MPI_SUM,MPI_COMM_WORLD,ll)
    call MPI_ALLREDUCE(Gamma_plus_reduce,Gamma_plus,Ntotal_plus,&
         MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ll)
    call MPI_ALLREDUCE(Gamma_minus_reduce,Gamma_minus,Ntotal_minus,&
         MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ll)
    call MPI_ALLREDUCE(rate_scatt_reduce,rate_scatt,Nbands*Nlist,MPI_DOUBLE_PRECISION,&
         MPI_SUM,MPI_COMM_WORLD,ll)

    deallocate(Indof2ndPhonon_plus_reduce)
    deallocate(Indof3rdPhonon_plus_reduce)
    deallocate(Indof2ndPhonon_minus_reduce)
    deallocate(Indof3rdPhonon_minus_reduce)
    deallocate(Gamma_plus_reduce)
    deallocate(Gamma_minus_reduce)
  end subroutine Ind_driver

  ! Compute the number of allowed absorption processes and their contribution
  ! to phase space.
  subroutine NP_plus(mm,energy,velocity,Nlist,List,IJK,N_plus,P_plus)
    implicit none

    integer(kind=4),intent(in) :: mm,NList,List(Nlist),IJK(3,nptk)
    real(kind=8),intent(in) :: energy(nptk,Nbands),velocity(nptk,Nbands,3)
    integer(kind=4),intent(out) :: N_plus
    real(kind=8),intent(out) :: P_plus

    integer(kind=4) :: q(3),qprime(3),qdprime(3),i,j,k
    integer(kind=4) :: Index_N(0:(Ngrid(1)-1),0:(Ngrid(2)-1),0:(Ngrid(3)-1))
    integer(kind=4) :: ii,jj,kk,ll,ss
    real(kind=8) :: sigma
    real(kind=8) :: omega,omegap,omegadp

    do ii=0,Ngrid(1)-1        ! G1 direction
       do jj=0,Ngrid(2)-1     ! G2 direction
          do kk=0,Ngrid(3)-1  ! G3 direction
             Index_N(ii,jj,kk)=(kk*Ngrid(2)+jj)*Ngrid(1)+ii+1
          end do
       end do
    end do
    N_plus=0
    P_plus=0.d00
    i=modulo(mm-1,Nbands)+1
    ll=int((mm-1)/Nbands)+1
    q=IJK(:,list(ll))
    omega=energy(list(ll),i)
    if(omega.ne.0) then
       do j=1,Nbands
          do ii=1,nptk
             qprime=IJK(:,ii)
             omegap=energy(ii,j)
             !--------BEGIN absorption process-----------
             do k=1,Nbands
                qdprime=q+qprime
                qdprime=modulo(qdprime,Ngrid)
                ss=Index_N(qdprime(1),qdprime(2),qdprime(3))
                omegadp=energy(ss,k)
                if ((omegap.ne.0).and.(omegadp.ne.0)) then
                   sigma=scalebroad*base_sigma(&
                        velocity(ii,j,:)-&
                        velocity(ss,k,:))
                   if(abs(omega+omegap-omegadp).le.(2.d0*sigma)) then
                      N_plus=N_plus+1
                      P_plus=P_plus+&
                           exp(-(omega+omegap-omegadp)**2/(sigma**2))/&
                           (sigma*sqrt(Pi)*nptk**2*nbands**3)
                   end if
                end if
             end do ! k
             !--------END absorption process-------------!
          end do ! ii
       end do  ! j
    end if
  end subroutine NP_plus

  ! Same as NP_plus, but for emission processes.
  subroutine NP_minus(mm,energy,velocity,Nlist,List,IJK,N_minus,P_minus)
    implicit none

    integer(kind=4),intent(in) :: mm,NList,List(Nlist),IJK(3,nptk)
    real(kind=8),intent(in) :: energy(nptk,Nbands),velocity(nptk,Nbands,3)
    integer(kind=4),intent(out) :: N_minus
    real(kind=8),intent(out) :: P_minus

    integer(kind=4) :: q(3),qprime(3),qdprime(3),i,j,k
    integer(kind=4) :: Index_N(0:(Ngrid(1)-1),0:(Ngrid(2)-1),0:(Ngrid(3)-1))
    integer(kind=4) :: ii,jj,kk,ll,ss
    real(kind=8) :: sigma
    real(kind=8) :: omega,omegap,omegadp

    do ii=0,Ngrid(1)-1        ! G1 direction
       do jj=0,Ngrid(2)-1     ! G2 direction
          do kk=0,Ngrid(3)-1  ! G3 direction
             Index_N(ii,jj,kk)=(kk*Ngrid(2)+jj)*Ngrid(1)+ii+1
          end do
       end do
    end do
    N_minus=0
    P_minus=0.d00
    i=modulo(mm-1,Nbands)+1
    ll=int((mm-1)/Nbands)+1
    q=IJK(:,list(ll))
    omega=energy(list(ll),i)
    if(omega.ne.0) then
       do j=1,Nbands
          do ii=1,nptk
             qprime=IJK(:,ii)
             omegap=energy(ii,j)
             !--------BEGIN emission process-----------
             do k=1,Nbands
                qdprime=q-qprime
                qdprime=modulo(qdprime,Ngrid)
                ss=Index_N(qdprime(1),qdprime(2),qdprime(3))
                omegadp=energy(ss,k)
                if ((omegap.ne.0).and.(omegadp.ne.0)) then
                   sigma=scalebroad*base_sigma(&
                        velocity(ii,j,:)-&
                        velocity(ss,k,:))
                   if(abs(omega-omegap-omegadp).le.(2.d0*sigma)) then
                      N_minus=N_minus+1
                      P_minus=P_minus+&
                           exp(-(omega-omegap-omegadp)**2/(sigma**2))/&
                           (sigma*sqrt(Pi)*nptk**2*nbands**3)
                   end if
                end if
             end do ! k
             !--------END emission process-------------!
          end do ! ii
       end do  ! j
    end if
  end subroutine NP_minus

  ! Wrapper around NP_plus and NP_minus that splits the work among processors.
  subroutine NP_driver(energy,velocity,Nlist,List,IJK,&
       N_plus,Pspace_plus_total,N_minus,Pspace_minus_total)
    implicit none

    include "mpif.h"

    real(kind=8),intent(in) :: energy(nptk,nbands)
    real(kind=8),intent(in) :: velocity(nptk,nbands,3)
    integer(kind=4),intent(in) :: NList
    integer(kind=4),intent(in) :: List(Nlist)
    integer(kind=4),intent(in) :: IJK(3,nptk)
    integer(kind=4),intent(out) :: N_plus(Nlist*Nbands)
    integer(kind=4),intent(out) :: N_minus(Nlist*Nbands)
    real(kind=8),intent(out) :: Pspace_plus_total(Nbands,Nlist)
    real(kind=8),intent(out) :: Pspace_minus_total(Nbands,Nlist)

    integer(kind=4) :: mm
    integer(kind=4) :: N_plus_reduce(Nlist*Nbands)
    integer(kind=4) :: N_minus_reduce(Nlist*Nbands)
    real(kind=8) :: Pspace_plus_reduce(Nlist*Nbands)
    real(kind=8) :: Pspace_minus_reduce(Nlist*Nbands)

    Pspace_plus_total=0.d0
    Pspace_plus_reduce=0.d0
    Pspace_minus_total=0.d0
    Pspace_minus_reduce=0.d0
    N_plus=0
    N_minus=0
    N_plus_reduce=0
    N_minus_reduce=0

    do mm=myid+1,Nbands*Nlist,numprocs
       call NP_plus(mm,energy,velocity,Nlist,List,IJK,&
            N_plus_reduce(mm),Pspace_plus_reduce(mm))
       call NP_minus(mm,energy,velocity,Nlist,List,IJK,&
            N_minus_reduce(mm),Pspace_minus_reduce(mm))
    end do

    call MPI_ALLREDUCE(N_plus_reduce,N_plus,Nbands*Nlist,MPI_INTEGER,&
         MPI_SUM,MPI_COMM_WORLD,mm)
    call MPI_ALLREDUCE(N_minus_reduce,N_minus,Nbands*Nlist,MPI_INTEGER,&
         MPI_SUM,MPI_COMM_WORLD,mm)
    call MPI_ALLREDUCE(Pspace_plus_reduce,Pspace_plus_total,Nbands*Nlist,&
         MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,mm)
    call MPI_ALLREDUCE(Pspace_minus_reduce,Pspace_minus_total,Nbands*Nlist,&
         MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,mm)
  end subroutine NP_driver

  ! RTA-only version of Ind_plus.
  subroutine RTA_plus(num_low_E_zxy,low_E_zxy,mm,energy,velocity,eigenvect,Nlist,List,&
       Ntri,Phi,R_j,R_k,Index_i,Index_j,Index_k,IJK,&
       Gamma_plus)
    implicit none

    integer(kind=4),intent(in) :: mm,NList,List(Nlist),IJK(3,nptk),Ntri
    integer(kind=4),intent(in) :: Index_i(Ntri),Index_j(Ntri),Index_k(Ntri)
    real(kind=8),intent(in) :: energy(nptk,Nbands),velocity(nptk,Nbands,3)
    real(kind=8),intent(in) :: Phi(3,3,3,Ntri),R_j(3,Ntri),R_k(3,Ntri)
    complex(kind=8),intent(in) :: eigenvect(nptk,Nbands,Nbands)
    real(kind=8),intent(out) :: Gamma_plus

    integer(kind=4) :: q(3),qprime(3),qdprime(3),i,j,k
    integer(kind=4) :: Index_N(0:(Ngrid(1)-1),0:(Ngrid(2)-1),0:(Ngrid(3)-1))
    integer(kind=4) :: ii,jj,kk,ll,ss,j_zxy,shang_zxy, rand_zxy!, ii_rand, shang_zxy_rand, j_rand
    real(kind=8) :: sigma
    real(kind=8) :: fBEprime,fBEdprime
    real(kind=8) :: omega,omegap,omegadp
    real(kind=8) :: realqprime(3),realqdprime(3)
    complex(kind=8) :: Vp
!modify zxy
integer(kind=4) :: n_zxy
integer(kind=4) :: m_zxy
!real :: random_real
integer ::  random_integer, count_zxy, target_integer_zxy

!integer, dimension(:), allocatable :: random_integers
real :: random_single
logical :: is_duplicate, is_present
 integer(kind=4), intent(in) :: num_low_E_zxy
integer,intent(in) ::low_E_zxy(num_low_E_zxy)
real, dimension(:), allocatable :: random_real

  n_zxy=num_low_E_zxy
  m_zxy=int(num_low_E_zxy*randq)
  allocate(random_real(m_zxy))
  call random_seed()
  count_zxy = 0
 
  rand_zxy=0 
  shang_zxy=0
!  do
    call random_number(random_real)
!zxy    random_integer = FLOOR(random_real * n_zxy) + 1

       !  ii_rand=modulo(random_integer,nptk) !modify zxy
       !  shang_zxy_rand=int(random_integer/nptk)
       !            j_rand=modulo(shang_zxy_rand,Nbands)+1
  !  is_duplicate = any(random_integers == random_integer)

  !  if (.not. is_duplicate ) then

   !   count_zxy = count_zxy + 1
   !   random_integers(count_zxy) = random_integer
   ! end if

 !   if (count_zxy == m_zxy) exit
 ! end do
!write(*,*) 'end random selection'
!modify zxy
    Gamma_plus=0.d00
    do ii=0,Ngrid(1)-1
       do jj=0,Ngrid(2)-1
          do kk=0,Ngrid(3)-1
             Index_N(ii,jj,kk)=(kk*Ngrid(2)+jj)*Ngrid(1)+ii+1
          end do
       end do
    end do
   
    i=int((mm-1)/Nlist)+1 !modify zxy
    ll=modulo(mm-1,Nlist)+1!modify zxy
   !zxy i=modulo(mm-1,Nbands)+1
   !zxy ll=int((mm-1)/Nbands)+1
    q=IJK(:,list(ll))
    omega=energy(list(ll),i)
    if(omega.ne.0) then 
       do j_zxy =1,m_zxy !modify zxy
          random_single=random_real(j_zxy-1)
          rand_zxy=FLOOR(random_single*n_zxy)+1
          ii=modulo(low_E_zxy(rand_zxy)-1,nptk)+1
           j=int((low_E_zxy(rand_zxy)-1)/nptk)+1
        ! ii=modulo(rand_zxy,nptk) !modify zxy
        ! shang_zxy=int(rand_zxy/nptk)
        !           j=modulo(shang_zxy,Nbands)+1
        !           k=int(shang_zxy/Nbands)+1
    !       write(*,*) 'ii j k random', ii, j, k, rand_zxy
    !   do j=1,Nbands
    !      do ii=1,nptk
             qprime=IJK(:,ii)
             realqprime=matmul(rlattvec,qprime)
             omegap=energy(ii,j)
             fBEprime=1.d0/(exp(hbar*omegap/Kb/T)-1.D0)
             !--------BEGIN absorption process-----------
             do k=1,Nbands
            !  target_integer_zxy=((k-1)*Nbands+(j-1))*nptk+ii !modify zxy
     !modify zxy
             !   is_present= any(random_integers==target_integer_zxy)
                !write(*,*) 'target process', is_present 
     !modify zxy
                qdprime=q+qprime
                qdprime=modulo(qdprime,Ngrid)
                realqdprime=matmul(rlattvec,qdprime)
                ss=Index_N(qdprime(1),qdprime(2),qdprime(3))
                omegadp=energy(ss,k)
                if ((omegap.ne.0).and.(omegadp.ne.0)) then
                   sigma=scalebroad*base_sigma(&
                        velocity(ii,j,:)-&
                        velocity(ss,k,:))
                   if(abs(omega+omegap-omegadp).le.(2.d0*sigma)) then
                      fBEdprime=1.d0/(exp(hbar*omegadp/Kb/T)-1.D0)
                   !  if(is_present) then !modify zxy
                      Vp=Vp_plus(i,j,k,list(ll),ii,ss,&
                           realqprime,realqdprime,eigenvect,&
                           Ntri,Phi,R_j,R_k,Index_i,Index_j,Index_k)
                      Gamma_plus=Gamma_plus+hbarp*pi/4.d0*(fBEprime-fBEdprime)*&
                           exp(-(omega+omegap-omegadp)**2/(sigma**2))/sigma/sqrt(Pi)/&
                           (omega*omegap*omegadp)*abs(Vp)**2
                    ! end if !modify zxy
                  end if
                end if
             end do ! k
             !--------END absorption process-------------!
     !     end do ! ii
     !  end do  ! j
      end do !modify zxy
    end if
!    write(*,*) 'mm', mm, Gamma_plus !modify zxy
    Gamma_plus=Gamma_plus*5.60626442*1.d8/nptk*n_zxy/m_zxy ! THz !modify zxy
   ! Gamma_plus=Gamma_plus*5.60626442*1.d8/nptk ! THz !modify zxy
  deallocate(random_real) 
  end subroutine RTA_plus

  ! RTA-only version of Ind_minus.
  subroutine RTA_minus(num_low_E_zxy,low_E_zxy,mm,energy,velocity,eigenvect,Nlist,List,&
       Ntri,Phi,R_j,R_k,Index_i,Index_j,Index_k,IJK,&
       Gamma_minus)
    implicit none

    integer(kind=4),intent(in) :: mm,NList,List(Nlist),IJK(3,nptk),Ntri
    integer(kind=4),intent(in) :: Index_i(Ntri),Index_j(Ntri),Index_k(Ntri)
    real(kind=8),intent(in) :: energy(nptk,Nbands),velocity(nptk,Nbands,3)
    real(kind=8),intent(in) :: Phi(3,3,3,Ntri),R_j(3,Ntri),R_k(3,Ntri)
    complex(kind=8),intent(in) :: eigenvect(nptk,Nbands,Nbands)
    real(kind=8),intent(out) :: Gamma_minus

    integer(kind=4) :: q(3),qprime(3),qdprime(3),i,j,k,N_minus_count
    integer(kind=4) :: Index_N(0:(Ngrid(1)-1),0:(Ngrid(2)-1),0:(Ngrid(3)-1))
    integer(kind=4) :: ii,jj,kk,ll,ss,j_zxy,shang_zxy, rand_zxy!, ii_rand, shang_zxy_rand, j_rand
    real(kind=8) :: sigma
    real(kind=8) :: fBEprime,fBEdprime
    real(kind=8) ::  omega,omegap,omegadp
    real(kind=8) :: realqprime(3),realqdprime(3)
    complex(kind=8) :: Vp
!modify zxy
integer(kind=4) :: n_zxy
integer(kind=4), intent(in) :: num_low_E_zxy
integer,intent(in) ::low_E_zxy(num_low_E_zxy)
integer(kind=4) :: m_zxy
real :: random_single
real, dimension(:), allocatable :: random_real
integer ::  random_integer, count_zxy, target_integer_zxy
!integer, dimension(:), allocatable :: random_integers
logical :: is_duplicate, is_present 
  !n_zxy=nptk*Nbands*Nbands
  n_zxy=num_low_E_zxy
  m_zxy=int(num_low_E_zxy*randq)
  allocate(random_real(m_zxy))
  call random_seed()

  !count_zxy = 0
  !random_integers = 0

  !do
    call random_number(random_real)
   ! random_integer = FLOOR(random_real * n_zxy) + 1

!         ii_rand=modulo(random_integer,nptk) !modify zxy
!         shang_zxy_rand=int(random_integer/nptk)
!                   j_rand=modulo(shang_zxy_rand,Nbands)+1
 !   is_duplicate = any(random_integers == random_integer)
!    if (.not. is_duplicate ) then
!      count_zxy = count_zxy + 1
!      random_integers(count_zxy) = random_integer
!    end if

!    if (count_zxy == m_zxy) exit
!  end do
!modify zxy

    Gamma_minus=0.d00
    do ii=0,Ngrid(1)-1
       do jj=0,Ngrid(2)-1
          do kk=0,Ngrid(3)-1
             Index_N(ii,jj,kk)=(kk*Ngrid(2)+jj)*Ngrid(1)+ii+1
          end do
       end do
    end do
    N_minus_count=0

    i=int((mm-1)/Nlist)+1 !modify zxy
    ll=modulo(mm-1,Nlist)+1!modify zxy
    !zxy i=modulo(mm-1,Nbands)+1
    !zxy ll=int((mm-1)/Nbands)+1
    q=IJK(:,list(ll))
    omega=energy(list(ll),i)
    if(omega.ne.0) then
   !    do j=1,Nbands
   !       do ii=1,nptk
     do j_zxy =1,m_zxy !modify zxy
          random_single=random_real(j_zxy-1) 
          rand_zxy=FLOOR(n_zxy*random_single)+1
         !ii=modulo(rand_zxy,nptk) !modify zxy
         !shang_zxy=int(rand_zxy/nptk)
                   !j=modulo(shang_zxy,Nbands)+1
                   !k=int(shang_zxy/Nbands)+1
           ii=modulo(low_E_zxy(rand_zxy)-1,nptk)+1
            j=int((low_E_zxy(rand_zxy)-1)/nptk)+1
             qprime=IJK(:,ii)
             realqprime=matmul(rlattvec,qprime)
             omegap=energy(ii,j)
             fBEprime=1.d0/(exp(hbar*omegap/Kb/T)-1.D0)
             !--------BEGIN emission process-----------
             do k=1,Nbands
             ! target_integer_zxy=((k-1)*Nbands+(j-1))*nptk+ii !modify zxy
      !modify zxy
              !  is_present= any(random_integers==target_integer_zxy)
                !write(*,*) 'target process', is_present 
     !modify zxy


                qdprime=q-qprime
                qdprime=modulo(qdprime,Ngrid)
                realqdprime=matmul(rlattvec,qdprime)
                ss=Index_N(qdprime(1),qdprime(2),qdprime(3))
                omegadp=energy(ss,k)
                if ((omegap.ne.0).and.(omegadp.ne.0)) then
                   sigma=scalebroad*base_sigma(&
                        velocity(ii,j,:)-&
                        velocity(ss,k,:))
                   if (abs(omega-omegap-omegadp).le.(2.d0*sigma)) then
                      fBEdprime=1.d0/(exp(hbar*omegadp/Kb/T)-1.D0)
                     ! if (is_present== .true.) then
                      Vp=Vp_minus(i,j,k,list(ll),ii,ss,&
                           realqprime,realqdprime,eigenvect,&
                           Ntri,Phi,R_j,R_k,Index_i,Index_j,Index_k)
                      Gamma_minus=Gamma_minus+hbarp*pi/4.d0*(fBEprime+fBEdprime+1)*&
                           exp(-(omega-omegap-omegadp)**2/(sigma**2))/sigma/sqrt(Pi)/&
                           (omega*omegap*omegadp)*abs(Vp)**2
                      end if
                   end if
               ! end if
            end do ! k
             !--------END emission process-------------
    !     end do ! ii
    !  end do  ! j
           end do !modify zxy
    end if
    Gamma_minus=Gamma_minus*5.60626442*1.d8/nptk*n_zxy/m_zxy !modify zxy
    !Gamma_minus=Gamma_minus*5.60626442*1.d8/nptk !modify zxy
    deallocate(random_real)
  end subroutine RTA_minus

  ! Wrapper around RTA_plus and RTA_minus that splits the work among processors.
  subroutine RTA_driver(energy,velocity,eigenvect,Nlist,List,IJK,&
       Ntri,Phi,R_j,R_k,Index_i,Index_j,Index_k,rate_scatt)
    implicit none

    include "mpif.h"

    real(kind=8),intent(in) :: energy(nptk,nbands)
    real(kind=8),intent(in) :: velocity(nptk,nbands,3)
    complex(kind=8),intent(in) :: eigenvect(nptk,Nbands,Nbands)
    integer(kind=4),intent(in) :: NList
    integer(kind=4),intent(in) :: List(Nlist)
    integer(kind=4),intent(in) :: IJK(3,nptk)
    integer(kind=4),intent(in) :: Ntri
    real(kind=8),intent(in) :: Phi(3,3,3,Ntri)
    real(kind=8),intent(in) :: R_j(3,Ntri)
    real(kind=8),intent(in) :: R_k(3,Ntri)
    integer(kind=4),intent(in) :: Index_i(Ntri)
    integer(kind=4),intent(in) :: Index_j(Ntri)
    integer(kind=4),intent(in) :: Index_k(Ntri)
    real(kind=8),intent(out) :: rate_scatt(Nbands,Nlist)

    integer(kind=4) :: i, i_zxy, l_zxy, num_low_E_zxy, num_low_E_zxy_re
    integer(kind=4) :: ll
    integer(kind=4) :: mm
    real(kind=8) :: Gamma_plus,Gamma_minus
    real(kind=8) :: rate_scatt_reduce(Nbands,Nlist)
    integer(kind=4) :: low_E_zxy0(nptk*Nbands),low_E_zxy_re0(Nlist*Nbands), mm_zzxxyy
    integer, allocatable :: low_E_zxy(:), low_E_zxy_re(:)
    rate_scatt=0.d00
    rate_scatt_reduce=0.d00
!modify zxy
num_low_E_zxy=0
low_E_zxy=0
low_E_zxy0=0
num_low_E_zxy_re=0
low_E_zxy_re=0
low_E_zxy_re0=0
do i_zxy=1,Nbands
   do l_zxy=1,nptk
    if (energy(l_zxy,i_zxy) .le. cutE) then
      num_low_E_zxy=num_low_E_zxy+1
      low_E_zxy0(num_low_E_zxy)=l_zxy+(i_zxy-1)*nptk
    end if
   end do
end do
allocate(low_E_zxy(num_low_E_zxy))
low_E_zxy = low_E_zxy0(1:num_low_E_zxy)
!modify zxy
!modify zxy find irreducible low energy index
do i_zxy=1,Nbands
   do l_zxy=1,Nlist
    if (energy(list(l_zxy),i_zxy) .le. cutE) then
      num_low_E_zxy_re=num_low_E_zxy_re+1
      low_E_zxy_re0(num_low_E_zxy_re)=l_zxy+(i_zxy-1)*Nlist
    end if
   end do
end do
allocate(low_E_zxy_re(num_low_E_zxy_re))
low_E_zxy_re = low_E_zxy_re0(1:num_low_E_zxy_re)
if (myid==0) then 
write(*,*) 'num_low_E_zxy', num_low_E_zxy
write(*,*) 'num_low_E_zxy_re', num_low_E_zxy_re
write(*,*) 'cutE,randq',cutE,randq
end if

!modify zxy
   !zxy do mm=myid+1,Nbands*NList,numprocs
    do mm_zzxxyy=myid+1,num_low_E_zxy_re,numprocs
        mm=low_E_zxy_re(mm_zzxxyy) !modify zxy
       ! i=modulo(mm_zzxxyy-1,Nbands)+1 
       ! ll=int((mm_zzxxyy-1)/Nbands)+1
         
            i=int((mm-1)/Nlist)+1 !modify zxy
            ll=modulo(mm-1,Nlist)+1!modify zxy
       call RTA_plus(num_low_E_zxy,low_E_zxy,mm,energy,velocity,eigenvect,Nlist,List,&
            Ntri,Phi,R_j,R_k,Index_i,Index_j,Index_k,IJK,&
            Gamma_plus)
       rate_scatt_reduce(i,ll)=rate_scatt_reduce(i,ll)+Gamma_plus
       call RTA_minus(num_low_E_zxy,low_E_zxy,mm,energy,velocity,eigenvect,Nlist,List,&
            Ntri,Phi,R_j,R_k,Index_i,Index_j,Index_k,IJK,&
            Gamma_minus)
       rate_scatt_reduce(i,ll)=rate_scatt_reduce(i,ll)+Gamma_minus*5.D-1
! write(*,*) 'i ll mm', i, ll, rate_scatt_reduce(i,ll)
    end do

    !zxy call MPI_ALLREDUCE(rate_scatt_reduce,rate_scatt,Nbands*Nlist,&
    !zxy     MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,mm)
     call MPI_ALLREDUCE(rate_scatt_reduce,rate_scatt,Nbands*Nlist,&
         MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,mm_zzxxyy)
   deallocate(low_E_zxy)
   deallocate(low_E_zxy_re)
  end subroutine RTA_driver
end module processes
