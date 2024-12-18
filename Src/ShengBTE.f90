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

! Main program.
program ShengBTE
  use config
  use input
  use processes
  use wedgetc
  use iterations
  use conductivity
  use scaling
  use phonon_routines
  use dos_routines
  use gruneisen
  use integrals
  implicit none

  include "mpif.h"

  real(kind=8) :: kappa_sg(3,3),kappa_old(3,3),relchange
  integer(kind=4) :: i,j,ii,jj,kk,ll,mm,nn
  real(kind=8),allocatable :: energy(:,:),q0(:,:),velocity(:,:,:),velocity_z(:,:)
  complex(kind=8),allocatable :: eigenvect(:,:,:)

  real(kind=8),allocatable :: grun(:,:)

  real(kind=8),allocatable :: rate_scatt(:,:)
  real(kind=8),allocatable :: tau_zero(:,:),tau(:,:),tau_b(:,:),tau2(:,:),tau_b2(:,:)
  real(kind=8),allocatable :: dos(:,:),pdos(:,:,:),rate_scatt_isotope(:,:)
  real(kind=8),allocatable :: F_n(:,:,:),F_n_0(:,:,:),F_n_aux(:,:)
  real(kind=8),allocatable :: ThConductivity(:,:,:)
  real(kind=8),allocatable :: ThConductivityMode(:,:,:,:)
  real(kind=8),allocatable :: ticks(:),cumulative_kappa(:,:,:,:)

  integer(kind=4) :: Ntri
  ! IJK are vectors of product(ngrid) points in the lattice coordinate
  ! system, with each component ranging from 0 to Ngrid(:)-1.  Index_N
  ! is a mapping of 3 indices for an individual q-point into one index.
  integer(kind=4),allocatable :: Index_i(:),Index_j(:),Index_k(:),IJK(:,:),Index_N(:,:,:)
  real(kind=8),allocatable :: Phi(:,:,:,:),R_j(:,:),R_k(:,:)

  integer(kind=4) :: nlist,Ntotal_plus,Ntotal_minus
  integer(kind=4),allocatable :: nequi(:),list(:),AllEquiList(:,:),TypeofSymmetry(:,:),eqclasses(:)
  integer(kind=4),allocatable :: N_plus(:),N_minus(:)
  integer(kind=4),allocatable :: Indof2ndPhonon_plus(:),Indof3rdPhonon_plus(:)
  integer(kind=4),allocatable :: Indof2ndPhonon_minus(:),Indof3rdPhonon_minus(:)
  real(kind=8) :: radnw,kappa_or_old
  real(kind=8),allocatable :: Gamma_plus(:),Gamma_minus(:)
  real(kind=8),allocatable :: Pspace_plus_total(:,:)
  real(kind=8),allocatable :: Pspace_minus_total(:,:)
  real(kind=8),allocatable :: ffunc(:,:),radnw_range(:),v_or(:,:),F_or(:,:)
  real(kind=8),allocatable :: kappa_or(:),kappa_wires(:,:),kappa_wires_reduce(:,:)

  integer(kind=4) :: iorient,ierr
  character(len=4) :: aux
  character(len=128) :: sorientation

  call MPI_INIT(ierr)
  call MPI_COMM_RANK(MPI_COMM_WORLD,myid,ierr)
  call MPI_COMM_SIZE(MPI_COMM_WORLD,numprocs,ierr)

  ! Read CONTROL and initialize variables such as the
  ! direct/reciprocal lattice vectors, the symmetry operations, the
  ! Pearson deviation coefficients related to isotopic disorder and so
  ! on and so forth.
  call read_config()

  allocate(energy(nptk,nbands))
  allocate(eigenvect(nptk,nbands,nbands))
  allocate(grun(nptk,nbands))
  allocate(q0(nptk,3))
  allocate(velocity(nptk,nbands,3))
  allocate(velocity_z(nptk,nbands))
  allocate(IJK(3,nptk))
  allocate(Index_N(0:(ngrid(1)-1),0:(ngrid(2)-1),0:(ngrid(3)-1)))
  allocate(F_n(nbands,nptk,3))
  allocate(F_n_0(nbands,nptk,3),F_n_aux(nbands,nptk))
  allocate(ThConductivity(nbands,3,3))
  allocate(ThConductivityMode(nptk,nbands,3,3))
  allocate(kappa_wires(nbands,nwires))
  allocate(kappa_wires_reduce(nbands,nwires))
  allocate(Nequi(nptk))
  allocate(List(nptk))
  allocate(AllEquiList(nsymm_rot,nptk))
  allocate(TypeOfSymmetry(nsymm_rot,nptk))
  allocate(eqclasses(nptk))
  allocate(ffunc(nptk,nbands))
  allocate(v_or(nptk,nbands))
  allocate(F_or(nbands,nptk))
  allocate(kappa_or(nbands))

  ! Obtain the q-point equivalence classes defined by symmetry
  ! operations.
  call Id2Ind(IJK)
  call wedge(Nlist,Nequi,List,ALLEquiList,TypeofSymmetry)
  do ll=1,Nlist
     do kk=1,Nequi(ll)
        eqclasses(ALLEquiList(kk,ll))=List(ll)
     end do
  end do
if (myid .eq. 0) then!modify zxy
write(*,*) 'wedge finished'!modify zxy
end if !modify zxy

  do ii=1,Ngrid(1)
     do jj=1,Ngrid(2)
        do kk=1,Ngrid(3)
           ll=((kk-1)*Ngrid(2)+(jj-1))*Ngrid(1)+ii
           q0(ll,:)=rlattvec(:,1)*(ii-1.0)/ngrid(1)+&
                rlattvec(:,2)*(jj-1.0)/ngrid(2)+&
                rlattvec(:,3)*(kk-1.0)/ngrid(3)
        end do
     end do
  end do
if (myid .eq. 0) then!modify zxy
write(*,*) 'q0 fininshed'!modify zxy
end if!modify zxy
  if(myid.eq.0) then
     open(1,file="BTE.qpoints",status="replace")
     do ll=1,Nlist
        write(1,"(I9,x,I9,x,3(E20.10,x))") List(ll),Nequi(ll),q0(List(ll),:)
     end do
     close(1)
     open(1,file="BTE.qpoints_full",status="replace")
     do ll=1,nptk
        write(1,"(I9,x,I9,x,3(E20.10,x))") ll,eqclasses(ll),q0(ll,:)
     end do
     close(1)
  end if

  ! Obtain the phonon spectrum from the 2nd-order force constants (in
  ! either of the two formats suported) and the dielectric parameters
  ! in CONTROL.
  if(myid.eq.0) then
     write(*,*) "Info: about to obtain the spectrum"
     if(espresso) then
        write(*,*) "Info: expecting Quantum Espresso 2nd-order format"
     else
        write(*,*) "Info: expecting Phonopy 2nd-order format"
     end if
  end if
  call eigenDM(energy,eigenvect,velocity)
  if(myid.eq.0)write(*,*) "Info: spectrum calculation finished"

  ! Compute the harmonic integrals: lattice specific heat and
  ! small-grain-limit reduced thermal conductivity. Write out this
  ! information, as well as the spectrum itself.
  if(myid.eq.0) then
     open(1,file="BTE.cv",status="replace")
     write(1,*) cv(energy)
     close(1)
  end if

  call kappasg(energy,velocity,kappa_sg)
  if(myid.eq.0) then
     open(1,file="BTE.kappa_sg",status="replace")
     write(1,"(9E20.10)") kappa_sg
     close(1)
  end if

  write(aux,"(I0)") 3*Nbands
  if(myid.eq.0) then
     open(1,file="BTE.v",status="replace")
     do ll=1,Nlist
        write(1,"("//trim(adjustl(aux))//"E20.10)") velocity(list(ll),:,:)
     end do
     close(1)
     open(1,file="BTE.v_full",status="replace")
     do ll=1,nptk
        write(1,"("//trim(adjustl(aux))//"E20.10)") velocity(ll,:,:)
     end do
  end if
  write(aux,"(I0)") Nbands
  if(myid.eq.0) then
     open(1,file="BTE.omega",status="replace")
     open(2,file="BTE.omega_full",status="replace")
     do ll=1,Nlist
        write(1,"("//trim(adjustl(aux))//"E20.10)") energy(list(ll),:)
     end do
     do ll=1,nptk
        write(2,"("//trim(adjustl(aux))//"E20.10)") energy(ll,:)
     end do
     close(1)
     close(2)
  end if

  ! Locally adaptive estimates of the total and projected densities of states.
  allocate(dos(Nbands,Nlist))
  allocate(pdos(Nbands,Nlist,natoms))
  allocate(rate_scatt_isotope(Nbands,Nlist))

  call calc_dos(energy,velocity,eigenvect,nlist,list,&
       dos,pdos,rate_scatt_isotope)

  if(myid.eq.0) then
     open(1,file="BTE.dos",status="replace")
     do mm=1,Nlist
        do nn=1,Nbands
           write(1,"(2E25.17)") energy(list(mm),nn),dos(nn,mm)
        end do
     end do
     close(1)
     write(aux,"(I0)") Natoms
     open(1,file="BTE.pdos",status="replace")
     do mm=1,Nlist
        do nn=1,Nbands
           write(1,"(E25.17,"//trim(adjustl(aux))//"E25.17)")&
                energy(list(mm),nn),pdos(nn,mm,:)
        end do
     end do
     close(1)
     write(aux,"(I0)") Nbands
     open(1,file="BTE.w_isotopic",status="replace")
     do ll=1,Nlist
        write(1,"("//trim(adjustl(aux))//"E20.10)") rate_scatt_isotope(:,ll)
     end do
     close(1)
  end if

  allocate(rate_scatt(Nbands,Nlist))
  allocate(tau_zero(Nbands,Nlist))
  allocate(tau(Nbands,Nlist))
  allocate(tau_b(Nbands,Nlist))
  allocate(tau2(Nbands,nptk))
  allocate(tau_b2(Nbands,nptk))
  rate_scatt=0.d0
  allocate(radnw_range(nwires))
  do ii=1,nwires
     radnw_range(ii)=rmin+(ii-1.0)*dr
  end do

  ! N_plus: number of allowed absorption processes
  ! N_minus: number of allowed emission processes.
!  allocate(N_plus(Nlist*Nbands)) !modify zxy
!  allocate(N_minus(Nlist*Nbands)) ! modify zxy
  ! Phase space volume per mode and their sum.
 ! allocate(Pspace_plus_total(Nbands,Nlist)) !modify zxy
 ! allocate(Pspace_minus_total(Nbands,Nlist)) !modify zxy

!zxy  call NP_driver(energy,velocity,Nlist,List,IJK,&
!zxy       N_plus,Pspace_plus_total,N_minus,Pspace_minus_total)

!zxy  Ntotal_plus=sum(N_plus)
!zxy  Ntotal_minus=sum(N_minus)

!zxy  if(myid.eq.0)write(*,*) "Info: Ntotal_plus =",Ntotal_plus
!zxy  if(myid.eq.0)write(*,*) "Info: Ntotal_minus =",Ntotal_minus

!zxy  if(myid.eq.0) then
!zxy     open(1,file="BTE.P3_plus",status="replace")
!zxy     do ll=1,Nlist
!zxy        write(1,"("//trim(adjustl(aux))//"E20.10)") Pspace_plus_total(:,ll)
!zxy     end do
!zxy    close(1)
!zxy     open(1,file="BTE.P3_minus",status="replace")
 !zxy    do ll=1,Nlist
 !zxy       write(1,"("//trim(adjustl(aux))//"E20.10)") Pspace_minus_total(:,ll)
 !zxy    end do
 !zxy    close(1)
 !zxy    open(1,file="BTE.P3",status="replace")
 !zxy    do ll=1,Nlist
 !zxy       write(1,"("//trim(adjustl(aux))//"E20.10)") 2.*(Pspace_plus_total(:,ll)+&
 !zxy            Pspace_minus_total(:,ll)/2.)/3.
 !zxy    end do
 !zxy    close(1)
 !zxy    do ii=1,Nlist
  !zxy      Pspace_plus_total(:,ii)=Pspace_plus_total(:,ii)*Nequi(ii)
 !zxy    end do
 !zxy    open(1,file="BTE.P3_plus_total",status="replace")
 !zxy    write(1,*) sum(Pspace_plus_total)
 !zxy    close(1)
 !zxy    do ii=1,Nlist
 !zxy       Pspace_minus_total(:,ii)=Pspace_minus_total(:,ii)*Nequi(ii)
 !zxy    end do
 !zxy    open(1,file="BTE.P3_minus_total",status="replace")
 !zxy    write(1,*) sum(Pspace_minus_total)
 !zxy    close(1)
 !zxy    open(1,file="BTE.P3_total",status="replace")
 !zxy    write(1,*) 2.*(sum(Pspace_plus_total)+sum(Pspace_minus_total)/2.)/3.
 !zxy    close(1)
  !zxy end if

 !zxy deallocate(Pspace_plus_total)
 !zxy deallocate(Pspace_minus_total)

  call MPI_BARRIER(MPI_COMM_WORLD,ierr)

  ! Up to this point, no anharmonic information is used.
  if(onlyharmonic) then
     write(*,*) "Info: onlyharmonic=.true., stopping here"
     call MPI_FINALIZE(ierr)
     stop
  end if

  ! Load the anharmonic IFCs from FORCE_CONSTANTS_3RD.
  call read3fc(Ntri,Phi,R_j,R_k,Index_i,Index_j,Index_k)

  call mode_grun(energy,eigenvect,Ntri,Phi,R_j,R_k,&
       Index_i,Index_j,Index_k,grun)
  write(aux,"(I0)") Nbands
  if(myid.eq.0) then
     open(1,file="BTE.gruneisen",status="replace")
     do ll=1,Nlist
        write(1,"("//trim(adjustl(aux))//"E20.10)") grun(list(ll),:)
     end do
     close(1)
     open(1,file="BTE.gruneisen_total",status="replace")
     write(1,*) total_grun(energy,grun)
     close(1)
  end if
  deallocate(grun)

  ! This is the most expensive part of the calculation: obtaining the
  ! three-phonon scattering amplitudes for all allowed processes.
  ! When the iterative solution to the full linearized BTE is not
  ! requested (i.e., when the relaxation-time approximation is
  ! enough) we use optimized routines with a much smaller memory footprint.
  if(convergence) then
     allocate(Indof2ndPhonon_plus(Ntotal_plus))
     allocate(Indof3rdPhonon_plus(Ntotal_plus))
     allocate(Indof2ndPhonon_minus(Ntotal_minus))
     allocate(Indof3rdPhonon_minus(Ntotal_minus))
     allocate(Gamma_plus(Ntotal_plus))
     allocate(Gamma_minus(Ntotal_minus))

     call Ind_driver(energy,velocity,eigenvect,Nlist,List,IJK,N_plus,N_minus,&
          Ntri,Phi,R_j,R_k,Index_i,Index_j,Index_k,&
          Indof2ndPhonon_plus,Indof3rdPhonon_plus,Gamma_plus,&
          Indof2ndPhonon_minus,Indof3rdPhonon_minus,Gamma_minus,rate_scatt)
  else
     call RTA_driver(energy,velocity,eigenvect,Nlist,List,IJK,&
          Ntri,Phi,R_j,R_k,Index_i,Index_j,Index_k,rate_scatt)
  end if

  write(aux,"(I0)") Nbands
  if(myid.eq.0) then
     open(1,file="BTE.w_anharmonic",status="replace")
     do ll=1,Nlist
        write(1,"("//trim(adjustl(aux))//"E20.10)") rate_scatt(:,ll)
     end do
     close(1)
  end if

  ! Obtain the total scattering rates in the relaxation time approximation.
  rate_scatt=rate_scatt+rate_scatt_isotope
  if(myid.eq.0) then
     open(1,file="BTE.w",status="replace")
     do ll = 1,Nlist
        write(1,"("//trim(adjustl(aux))//"E20.10)") rate_scatt(:,ll)
     end do
     close(1)
  end if

  tau_zero=0.d0
  do ll = 1,Nlist
     do i=1,Nbands
        if(rate_scatt(i,ll).ne.0) then
           tau_zero(i,ll)=1./rate_scatt(i,ll)
        end if
     end do
  end do

  ! Set up everything to start the iterative process.
  call iteration0(Nlist,Nequi,ALLEquiList,energy,velocity,tau_zero,F_n)
  F_n_0=F_n
  if(myid.eq.0) then
     ! Open all output files.
     open(2001,file="BTE.kappa",status="replace")
     open(2002,file="BTE.kappa_tensor",status="replace")
     open(2003,file="BTE.kappa_scalar",status="replace")
     call TConduct(energy,velocity,F_n,ThConductivity,ThConductivityMode)
     write(aux,"(I0)") 9*Nbands
     write(2001,"(I9,"//trim(adjustl(aux))//"E20.10)") 0,ThConductivity
     write(2002,"(I9,9E20.10,E20.10)") 0,sum(ThConductivity,dim=1)
     write(2003,"(I9,E20.10,E20.10)") 0,&
          sum(sum(ThConductivity,dim=1),reshape((/((i==j,i=1,3),j=1,3)/),(/3,3/)))/3.

     open(2004,file="BTE.kappa_mode",status="replace")
     do ll = 1,nptk
        write(2004,"("//trim(adjustl(aux))//"E20.10)") ThConductivityMode(ll,:,:,:)
     end do
     close(2004)

     ! Iterate to convergence if desired.
     if(convergence) then
        do ii=1,maxiter
           kappa_old=sum(ThConductivity,dim=1)
           call iteration(Nlist,Nequi,ALLEquiList,TypeofSymmetry,N_plus,N_minus,&
                Ntotal_plus,Ntotal_minus,Indof2ndPhonon_plus,Indof3rdPhonon_plus,&
                Indof2ndPhonon_minus,Indof3rdPhonon_minus,energy,velocity,&
                Gamma_plus,Gamma_minus,tau_zero,F_n)
           call TConduct(energy,velocity,F_n,ThConductivity,ThConductivityMode)
           write(2001,"(I9,"//trim(adjustl(aux))//"E20.10)") ii,ThConductivity
           write(2002,"(I9,9E20.10)") ii,sum(ThConductivity,dim=1)
           write(2003,"(I9,E20.10)") ii,&
                sum(sum(ThConductivity,dim=1),reshape((/((i==j,i=1,3),j=1,3)/),(/3,3/)))/3.
           relchange=twonorm3x3(sum(ThConductivity,dim=1)-kappa_old)/&
                twonorm3x3(kappa_old)
           write(*,*) "Info: Iteration",ii
           write(*,*) "Info:","Relative change","=",relchange
           if(relchange.lt.eps)exit
        end do

        open(2004,file="BTE.kappa_mode",status="replace")       ! output the converged values
        do ll = 1,nptk
           write(2004,"("//trim(adjustl(aux))//"E20.10)") ThConductivityMode(ll,:,:,:)
        end do
        close(2004)
     end if
     close(2001)
     close(2002)
     close(2003)

     ! Write out the converged scattering rates.
     do ll=1,Nlist
        do ii=1,Nbands
           tau(ii,ll)=dot_product(F_n(ii,List(ll),:),velocity(List(ll),ii,:))/&
                (dot_product(velocity(List(ll),ii,:),velocity(List(ll),ii,:))*energy(List(ll),ii))
           tau_b(ii,ll)=1/dot_product(velocity(List(ll),ii,:),velocity(List(ll),ii,:))
        end do
     end do
     write(aux,"(I0)") Nbands
     open(1,file="BTE.w_final",status="replace")
     open(2,file="BTE.w_boundary",status="replace")
     do ll = 1,Nlist
        write(1,"("//trim(adjustl(aux))//"E20.10)") 1./tau(:,ll)
        write(2,"("//trim(adjustl(aux))//"E20.10)") 1./tau_b(:,ll)
     end do
     close(1)
     close(2)
     do ll=1,nptk
        do ii=1,Nbands
           tau2(ii,ll)=dot_product(F_n(ii,ll,:),velocity(ll,ii,:))/&
                (dot_product(velocity(ll,ii,:),velocity(ll,ii,:))*energy(ll,ii))
           tau_b2(ii,ll)=1/dot_product(velocity(ll,ii,:),velocity(ll,ii,:))
        end do
     end do
     write(aux,"(I0)") Nbands
     open(1,file="BTE.w_final_full",status="replace")
     open(2,file="BTE.w_boundary_full",status="replace")
     do ll = 1,nptk
        write(1,"("//trim(adjustl(aux))//"E20.10)") 1./tau2(:,ll)
        write(2,"("//trim(adjustl(aux))//"E20.10)") 1./tau_b2(:,ll)
     end do
     close(1)
     close(2)

     ! If results for nanowires have been requested, obtain a lower bound
     ! for the thermal conductivity along each crystallographic orientation
     ! by using the bulk RTA results.
     if(nanowires) then
        do iorient=1,norientations
           write(sorientation,"(I128)") iorient
           open(3001,file="BTE.kappa_nw_"//trim(adjustl(sorientation))//"_lower",status="replace")
           do ii=1,nptk
              do jj=1,Nbands
                 v_or(ii,jj)=dot_product(velocity(ii,jj,:),uorientations(:,iorient))
                 F_or(jj,ii)=dot_product(F_n_0(jj,ii,:),uorientations(:,iorient))
              end do
           end do
           do mm=1,Nwires
              radnw=radnw_range(mm)
              call ScalingOfTau(Nlist,Nequi,ALLEquiList,v_or,velocity,tau_zero,radnw,ffunc)
              do ii=1,nptk
                 do jj=1,Nbands
                    F_n_aux(jj,ii)=F_or(jj,ii)*ffunc(ii,jj)
                 end do
              end do
              call TConductScalar(energy,v_or,F_n_aux,kappa_or)
              write(3001,"(E30.20,"//trim(adjustl(aux))//"E20.10,E20.10)") 2.d0*radnw,&
                   kappa_or,sum(kappa_or)
           end do
           close(3001)
        end do
     end if
     allocate(ticks(nticks),cumulative_kappa(nbands,3,3,nticks))
     ! Cumulative thermal conductivity.
     call CumulativeTConduct(energy,velocity,F_n,ticks,cumulative_kappa)
     write(aux,"(I0)") 9*nbands+1
     open(2001,file="BTE.cumulative_kappa",status="replace")
     open(2002,file="BTE.cumulative_kappa_tensor",status="replace")
     open(2003,file="BTE.cumulative_kappa_scalar",status="replace")
     do ii=1,nticks
        write(2001,"("//trim(adjustl(aux))//"E20.10)") ticks(ii),cumulative_kappa(:,:,:,ii)
        write(2002,"(10E20.10)") ticks(ii),&
             sum(cumulative_kappa(:,:,:,ii),dim=1)
        write(2003,"(2E20.10)") ticks(ii),&
             sum(sum(cumulative_kappa(:,:,:,ii),dim=1),&
             reshape((/((i==j,i=1,3),j=1,3)/),(/3,3/)))/3.
     end do
     close(2001)
     close(2002)
     close(2003)
     deallocate(ticks,cumulative_kappa)
  end if

  call MPI_BARRIER(MPI_COMM_WORLD,ierr)

  ! If results for nanowires have been requested, repeat the iterative process
  ! for each desired orientation, introducing the appropriate scaling of
  ! relaxation times.
  if(nanowires) then
     kappa_wires=0.d00
     kappa_wires_reduce=0.d00
     kk=ceiling(float(nwires)/numprocs)
     do iorient=1,norientations
        if(myid.eq.0) then
           write(*,"(A,I0,A,3(x,I0))") "Info: nanowires with orientation ",&
                iorient,":",orientations(:,iorient)
        end if
        write(sorientation,"(I128)") iorient
        do ii=1,nptk
           do jj=1,Nbands
              v_or(ii,jj)=dot_product(velocity(ii,jj,:),uorientations(:,iorient))
              F_or(jj,ii)=dot_product(F_n_0(jj,ii,:),uorientations(:,iorient))
           end do
        end do
        do mm=myid+1,nwires,numprocs
           radnw=radnw_range(mm)
           call ScalingOfTau(Nlist,Nequi,ALLEquiList,v_or,velocity,tau_zero,radnw,ffunc)
           do ii=1,nptk
              do jj=1,Nbands
                 F_n_aux(jj,ii)=F_or(jj,ii)*ffunc(ii,jj)
              end do
           end do
           call TConductScalar(energy,v_or,F_n_aux,kappa_or)
           if(convergence) then
              do ii=1,maxiter
                 kappa_or_old=sum(kappa_or)
                 call iteration_scalar(Nlist,Nequi,ALLEquiList,TypeofSymmetry,N_plus,N_minus,&
                      Ntotal_plus,Ntotal_minus,Indof2ndPhonon_plus,Indof3rdPhonon_plus,&
                      Indof2ndPhonon_minus,Indof3rdPhonon_minus,energy,v_or,&
                      Gamma_plus,Gamma_minus,tau_zero,F_n_aux)
                 do ll=1,nptk
                    do jj=1,nbands
                       F_n_aux(jj,ll)=F_n_aux(jj,ll)*ffunc(ll,jj)
                    end do
                 end do
                 call TConductScalar(energy,v_or,F_n_aux,kappa_or)
                 relchange=abs((sum(kappa_or)-kappa_or_old)/kappa_or_old)
                 if(relchange.lt.eps)exit
              end do
           end if
           kappa_wires_reduce(:,mm)=kappa_or
        end do
        call MPI_ALLREDUCE(kappa_wires_reduce,kappa_wires,Nbands*Nwires,&
             MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)
        if(myid.eq.0) then
           write(aux,"(I0)") 3*nbands
           open(3001,file="BTE.kappa_nw_"//trim(adjustl(sorientation)),status="replace")
           do ii=1,Nwires
              radnw=radnw_range(ii)
              write(3001,"(E30.20,"//trim(adjustl(aux))//"E20.10,E20.10)") 2.d0*radnw,&
                   kappa_wires(:,ii),sum(kappa_wires(:,ii))
           end do
           close(3001)
        end if
     end do
  end if

  if(myid.eq.0)write(*,*) "Info: normal exit"

  call free_config()
  call MPI_BARRIER(MPI_COMM_WORLD,ierr)
  call MPI_FINALIZE(ierr)
end program ShengBTE
