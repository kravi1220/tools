
           subroutine mexfunction(nlhs, plhs, nrhs, prhs)
C-----------------------------------------------------------------------
C     (integer) Replace integer by integer*8 on the DEC Alpha and the
C     SGI 64-bit platforms
C
      integer*8 plhs(*), prhs(*)
      integer*8 Xpos,Ypos,Xgrd,Ygrd,Ipos,Jpos,angler
      integer*8 mxGetPr, mxCreateFull
C-----------------------------------------------------------------------
C
      integer nlhs, nrhs, mxGetM, mxGetN
      integer m_in, n_in, size, Npos, Mp, Lp
	


!  matlab call:
!  [Ipos,Jpos]=rnt_findIJ(Xpos,Ypos,Xgrd,Ygrd,angler)

      if(nrhs .ne. 5) then
         print*, 'ERROR: Five inputs needed. (Manu)'
       return
      endif

! get address of input      arrays
        Xpos = mxGetPr(prhs(1))
        Ypos = mxGetPr(prhs(2))
        Xgrd = mxGetPr(prhs(3))
        Ygrd = mxGetPr(prhs(4))
	  angler = mxGetPr(prhs(5))
	  

! set output matrix according to sizes
      m_in = mxGetM(prhs(1))
      n_in = mxGetN(prhs(1))
      Npos = m_in * n_in
      plhs(1) = mxCreateFull(m_in, n_in, 0)
      Ipos = mxGetPr(plhs(1))
      plhs(2) = mxCreateFull(m_in, n_in, 0)
	Jpos = mxGetPr(plhs(2))     

!get size of Xgrd
      Lp = mxGetM(prhs(3))
      Mp = mxGetN(prhs(3))

!      print *, 'Lp,Mp' , Lp, Mp, Npos

      
      call hindices(%val(Ipos),%val(Jpos),%val(Xpos),%val(Ypos),
     c        %val(angler),%val(Xgrd),%val(Ygrd),Npos,Lp,Mp)    
      return
      end


      subroutine hindices (Ipos,Jpos,Xpos,Ypos,angler,Xgrd,Ygrd,
     c                     Npos,Lp,Mp)
!
!================================================ Hernan G. Arango ===
!  Copyright (c) 2000 Rutgers/UCLA                                   !
!======================================== Alexander F. Shchepetkin ===
!                                                                    !
!  Given position vectors Xpos and Ypos of size Npos,  this routine  !
!  finds the corresponding indices Ipos and Jpos of the  model grid  !
!  (Xgrd,Ygrd) cell containing each requested position.              !
!                                                                    !
!  Calls:    Try_Range                                               !
!                                                                    !
!=====================================================================
!
      implicit none
      integer
     &        Lm, Mm, N, NAT
!      parameter (Lm=54,  Mm=108,  N=4, NAT=1)
      parameter ( N=4, NAT=1)	

      integer
     &        L, Lp, Lm2, M, Mp, Mm2, Nm, Np, NT, NSV
!      parameter (L=Lm+1, Lp=Lm+2, Lm2=Lm-1, Np=N+1,
!     &           M=Mm+1, Mp=Mm+2, Mm2=Mm-1, Nm=N-1, NT=NAT+NBT,
!     &           NSV=5+NT)
!      integer
!     &        padd_X, padd_E
!      parameter (padd_X=(Lm+2)/2-(Lm+1)/2,
!     &           padd_E=(Mm+2)/2-(Mm+1)/2)
!
!
      logical found, spherical
      logical Try_Range
      integer
     &        Imax, Imin, Jmax, Jmin, Npos, i0, j0, k
      real*8
     &        Ipos(Npos), Jpos(Npos), Xpos(Npos), Ypos(Npos), dx, dy
      real*8
     &        Xgrd(0:Lp-1,0:Mp-1), angler(0:Lp-1,0:Mp-1),
     &        Ygrd(0:Lp-1,0:Mp-1),deg2rad,pi, Eradius
     
      parameter ( pi =  3.14159265358979323846d0)
      parameter( deg2rad = pi / 180.0d0, Eradius = 6371315.0d0)

!
!  Local variable declarations.
!

      real*8 aa2, ang, bb2, diag2, phi
      real*8 xfac, xpp, yfac, ypp

       L=Lp-1
	 M=Mp-1
	 Mm=Mp-2
	 Lm=Lp-2
       spherical = .true.
!       print *, 'Lp,Mp' , Lp, Mp, Npos
!	 print *, Xpos , 'ciao  ',Xgrd(10,10) 

!
!-----------------------------------------------------------------------
!  Determine grid cell indices containing requested position points.
!  Then, interpolate to fractional cell position.
!-----------------------------------------------------------------------
!
!  Initialize all indices.
!
      DO k=1,Npos
        Ipos(k)=0
        Jpos(k)=0
      END DO
!
!  Check each position to find if it falls inside the whole domain.
!  Once it is stablished that it inside, find the exact cell to which
!  it belongs by successively dividing the domain by a half (binary
!  search).
!
      DO k=1,Npos
        found=Try_Range(Xgrd, Ygrd,0, L, 0, M,
     &                  Xpos(k), Ypos(k),Lp,Mp)
        if (found) THEN
          Imin=0
          Imax=L
          Jmin=0
          Jmax=M
          DO while (((Imax-Imin).gt.1).or.((Jmax-Jmin).gt.1))
            IF ((Imax-Imin).gt.1) THEN
              i0=(Imin+Imax)/2
              found=Try_Range(Xgrd, Ygrd,                               
     &                        Imin, i0, Jmin, Jmax,                     
     &                        Xpos(k), Ypos(k),Lp,Mp)
              IF (found) THEN
                Imax=i0
              ELSE
                Imin=i0
              END IF
            END IF
            IF ((Jmax-Jmin).gt.1) THEN
              j0=(Jmin+Jmax)/2
              found=Try_Range(Xgrd, Ygrd,                               
     &                        Imin, Imax, Jmin, j0,                     
     &                        Xpos(k), Ypos(k),Lp,Mp)
              IF (found) THEN
                Jmax=j0
              ELSE
                Jmin=j0
              END IF
            END IF
          END DO
!
!  Knowing the correct cell, calculate the exact indices, accounting
!  for a possibly rotated grid.  If spherical, convert all positions
!  to meters first.
!
          IF (spherical) THEN
            yfac=Eradius*deg2rad
            xfac=yfac*DCOS(Ypos(k)*deg2rad)
            xpp=(Xpos(k)-Xgrd(Imin,Jmin))*xfac
            ypp=(Ypos(k)-Ygrd(Imin,Jmin))*yfac
          ELSE
            xfac=1.0d0
            yfac=1.0d0
            xpp=Xpos(k)-Xgrd(Imin,Jmin)
            ypp=Ypos(k)-Ygrd(Imin,Jmin)
          END IF
!
!  Use Law of Cosines to get cell parallelogram "shear" angle.
!
          diag2=(Xgrd(Imin+1,Jmin)-Xgrd(Imin,Jmin+1))**2+               
     &          (Ygrd(Imin+1,Jmin)-Ygrd(Imin,Jmin+1))**2
          aa2=(Xgrd(Imin,Jmin)-Xgrd(Imin+1,Jmin))**2+                   
     &        (Ygrd(Imin,Jmin)-Ygrd(Imin+1,Jmin))**2
          bb2=(Xgrd(Imin,Jmin)-Xgrd(Imin,Jmin+1))**2+                   
     &        (Ygrd(Imin,Jmin)-Ygrd(Imin,Jmin+1))**2
          phi=DASIN((diag2-aa2-bb2)/(2.0d0*DSQRT(aa2*bb2)))
!
!  Transform float position into curvilinear coordinates. Assume the
!  cell is rectanglar, for now.
!
          ang=angler(Imin,Jmin)
          dx=xpp*DCOS(ang)+ypp*DSIN(ang)
          dy=ypp*DCOS(ang)-xpp*DSIN(ang)
!
!  Correct for parallelogram.
!
          dx=dx+dy*DTAN(phi)
          dy=dy/DCOS(phi)
!
!  Scale with cell side lengths to translate into cell indices.
!
          dx=MIN(MAX(0.0d0,dx/DSQRT(aa2)/xfac),1.0d0)
          dy=MIN(MAX(0.0d0,dy/DSQRT(bb2)/yfac),1.0d0)
          Ipos(k)=DFLOAT(Imin)+dx
          Jpos(k)=DFLOAT(Jmin)+dy
        END IF
      END DO
	
	do k=1,Npos
        Ipos(k)=Ipos(k)+1
        Jpos(k)=Jpos(k)+1
      enddo

      return
      end





!%==========================================================
!%	TryRange
!%==========================================================




!      function Try_Range (Imin,Imax,Jmin,Jmax,Xo,Yo,Xgrd,Ygrd,Lp,Mp)
      function Try_Range (Xgrd, Ygrd,Imin, Imax, Jmin, Jmax, 
     &                    Xo, Yo,Lp,Mp)
	
!
!================================================ Hernan G. Arango ===
!  Copyright (c) 2000 Rutgers/UCLA                                   !
!======================================== Alexander F. Shchepetkin ===
!                                                                    !
!  Given a grided domain with matrix coordinates Xgrd and Ygrd, this !
!  function finds if the point (Xo,Yo)  is inside the box defined by !
!  the requested corners (Imin,Jmin) and (Imax,Jmax). It will return !
!  logical switch  Try_Range=.true.  if (Xo,Yo) is inside, otherwise !
!  it will return false.                                             !
!                                                                    !
!  Calls:   inside                                                   !
!                                                                    !
!=====================================================================
!
      implicit none
      integer
     &        Lm, Mm, N, NAT
!      parameter (Lm=54,  Mm=108,  N=4, NAT=1)
      parameter ( N=4, NAT=1)	

      integer
     &        L, Lp, Lm2, M, Mp, Mm2, Nm, Np, NT, NSV
!      parameter (L=Lm+1, Lp=Lm+2, Lm2=Lm-1, Np=N+1,
!     &           M=Mm+1, Mp=Mm+2, Mm2=Mm-1, Nm=N-1, NT=NAT+NBT,
!     &           NSV=5+NT)
!     integer
!     &        padd_X, padd_E
!      parameter (padd_X=(Lm+2)/2-(Lm+1)/2,
!     &           padd_E=(Mm+2)/2-(Mm+1)/2)
!
      logical Try_Range, inside
      integer
     &        Imax, Imin, Jmax, Jmin, Nb, NX, i, j, shft
!      parameter (NX=2*Lp+2*Mp+1)
      real*8
     &        Xb(2*Lp+2*Mp+1), Yb(2*Lp+2*Mp+1), Xo, Yo
      real*8
     &        Xgrd(0:Lp-1,0:Mp-1),
     &        Ygrd(0:Lp-1,0:Mp-1)
     
       NX=2*Lp+2*Mp+1
       L=Lp-1
	 M=Mp-1
	 Mm=Mp-2
	 Lm=Lp-2
!
!---------------------------------------------------------------------
!  Define closed polygon.
!---------------------------------------------------------------------
!
!  Note that the last point (Xb(Nb),Yb(Nb)) does not repeat first
!  point (Xb(1),Yb(1)).  Instead, in function inside, it is implied
!  that the closing segment is (Xb(Nb),Yb(Nb))-->(Xb(1),Yb(1)). In
!  fact, function inside sets Xb(Nb+1)=Xb(1) and Yb(Nb+1)=Yb(1).
!
      Nb=2*(Jmax-Jmin+Imax-Imin)
      shft=1-Imin
      do i=Imin,Imax-1
        Xb(i+shft)=Xgrd(i,Jmin)
        Yb(i+shft)=Ygrd(i,Jmin)
      enddo
      shft=1-Jmin+Imax-Imin
      do j=Jmin,Jmax-1
        Xb(j+shft)=Xgrd(Imax,j)
        Yb(j+shft)=Ygrd(Imax,j)
      enddo
      shft=1+Jmax-Jmin+2*Imax-Imin
      do i=Imax,Imin+1,-1
        Xb(shft-i)=Xgrd(i,Jmax)
        Yb(shft-i)=Ygrd(i,Jmax)
      enddo
      shft=1+2*Jmax-Jmin+2*(Imax-Imin)
      do j=Jmax,Jmin+1,-1
        Xb(shft-j)=Xgrd(Imin,j)
        Yb(shft-j)=Ygrd(Imin,j)
      enddo
!
!---------------------------------------------------------------------
!  Check if point (Xo,Yo) is inside of the defined polygon.
!---------------------------------------------------------------------
!
      Try_Range=inside(Xo,Yo,Xb,Yb,Nb)
      return
      end






!%==========================================================
!%	INSIDE
!%==========================================================

      function inside (Xo,Yo,Xb,Yb,Nb)
!
!================================================ Hernan G. Arango ===
!  Copyright (c) 2000 Rutgers/UCLA                                   !
!======================================== Alexander F. Shchepetkin ===
!                                                                    !
!  Given the vectors Xb and Yb of size Nb, defining the coordinates  !
!  of a closed polygon,  this function find if the point (Xo,Yo) is  !
!  inside the polygon.  If the point  (Xo,Yo)  falls exactly on the  !
!  boundary of the polygon, it still considered inside.              !
!                                                                    !
!  This algorithm does not rely on the setting of  Xb(Nb)=Xb(1) and  !
!  Yb(Nb)=Yb(1).  Instead, it assumes that the last closing segment  !
!  is (Xb(Nb),Yb(Nb)) --> (Xb(1),Yb(1)).                             !
!                                                                    !
!  Reference:                                                        !
!                                                                    !
!    Reid, C., 1969: A long way from Euclid. Oceanography EMR,       !
!      page 174.                                                     !
!                                                                    !
!  Algorithm:                                                        !
!                                                                    !
!  The decision whether the point is  inside or outside the polygon  !
!  is done by counting the number of crossings from the ray (Xo,Yo)  !
!  to (Xo,-infinity), hereafter called meridian, by the boundary of  !
!  the polygon.  In this counting procedure,  a crossing is counted  !
!  as +2 if the crossing happens from "left to right" or -2 if from  !
!  "right to left". If the counting adds up to zero, then the point  !
!  is outside.  Otherwise,  it is either inside or on the boundary.  !
!                                                                    !
!  This routine is a modified version of the Reid (1969) algorithm,  !
!  where all crossings were counted as positive and the decision is  !
!  made  based on  whether the  number of crossings is even or odd.  !
!  This new algorithm may produce different results  in cases where  !
!  Xo accidentally coinsides with one of the (Xb(k),k=1:Nb) points.  !
!  In this case, the crossing is counted here as +1 or -1 depending  !
!  of the sign of (Xb(k+1)-Xb(k)).  Crossings  are  not  counted if  !
!  Xo=Xb(k)=Xb(k+1).  Therefore, if Xo=Xb(k0) and Yo>Yb(k0), and if  !
!  Xb(k0-1) < Xb(k0) < Xb(k0+1),  the crossing is counted twice but  !
!  with weight +1 (for segments with k=k0-1 and k=k0). Similarly if  !
!  Xb(k0-1) > Xb(k0) > Xb(k0+1), the crossing is counted twice with  !
!  weight -1 each time.  If,  on the other hand,  the meridian only  !
!  touches the boundary, that is, for example, Xb(k0-1) < Xb(k0)=Xo  !
!  and Xb(k0+1) < Xb(k0)=Xo, then the crossing is counted as +1 for  !
!  segment k=k0-1 and -1 for segment k=k0, resulting in no crossing. !
!                                                                    !
!  Note 1: (Explanation of the logical condition)                    !
!                                                                    !
!  Suppose  that there exist two points  (x1,y1)=(Xb(k),Yb(k))  and  !
!  (x2,y2)=(Xb(k+1),Yb(k+1)),  such that,  either (x1 < Xo < x2) or  !
!  (x1 > Xo > x2).  Therefore, meridian x=Xo intersects the segment  !
!  (x1,y1) -> (x2,x2) and the ordinate of the point of intersection  !
!  is:                                                               !
!                                                                    !
!                 y1*(x2-Xo) + y2*(Xo-x1)                            !
!             y = -----------------------                            !
!                          x2-x1                                     !
!                                                                    !
!  The mathematical statement that point  (Xo,Yo)  either coinsides  !
!  with the point of intersection or lies to the north (Yo>=y) from  !
!  it is, therefore, equivalent to the statement:                    !
!                                                                    !
!         Yo*(x2-x1) >= y1*(x2-Xo) + y2*(Xo-x1),   if   x2-x1 > 0    !
!  or                                                                !
!         Yo*(x2-x1) <= y1*(x2-Xo) + y2*(Xo-x1),   if   x2-x1 < 0    !
!                                                                    !
!  which, after noting that  Yo*(x2-x1) = Yo*(x2-Xo + Xo-x1) may be  !
!  rewritten as:                                                     !
!                                                                    !
!        (Yo-y1)*(x2-Xo) + (Yo-y2)*(Xo-x1) >= 0,   if   x2-x1 > 0    !
!  or                                                                !
!        (Yo-y1)*(x2-Xo) + (Yo-y2)*(Xo-x1) <= 0,   if   x2-x1 < 0    !
!                                                                    !
!  and both versions can be merged into  essentially  the condition  !
!  that (Yo-y1)*(x2-Xo)+(Yo-y2)*(Xo-x1) has the same sign as x2-x1.  !
!  That is, the product of these two must be positive or zero.       !
!                                                                    !
!=====================================================================
!
      implicit none
!
      logical inside
      integer
     &        Nb, Nstep, crossings, i, inc, k, kk, nc
      parameter (Nstep=128)
      integer
     &        index(Nstep)
      real*8
     &        Xb(Nb+1), Yb(Nb+1), Xo, Yo, dx1, dx2, dxy

!
!---------------------------------------------------------------------
!  Find intersections.
!---------------------------------------------------------------------
!
!  Set crossings counter and close the contour of the polygon.
!
      crossings=0
      Xb(Nb+1)=Xb(1)
      Yb(Nb+1)=Yb(1)
!
!  The search is optimized.  First select the indices of segments
!  where Xb(k) is different from Xb(k+1) and Xo falls between them.
!  Then, further investigate these segments in a separate loop.
!  Doing it in two stages takes less time because the first loop is
!  pipelined.
!
      do kk=0,Nb-1,Nstep
        nc=0
        do k=kk+1,MIN(kk+Nstep,Nb)
          if (((Xb(k+1)-Xo)*(Xo-Xb(k)).ge.0.0).and.
     &        (Xb(k).ne.Xb(k+1))) then
            nc=nc+1
            index(nc)=k
          endif
        enddo
        do i=1,nc
          k=index(i)
          if (Xb(k).ne.Xb(k+1)) then
            dx1=Xo-Xb(k)
            dx2=Xb(k+1)-Xo
            dxy=dx2*(Yo-Yb(k))-dx1*(Yb(k+1)-Yo)
            inc=0
            if ((Xb(k).eq.Xo).and.(Yb(k).eq.Yo)) then
              crossings=1
              goto 10
            elseif (((dx1.eq.0.0).and.(Yo.ge.Yb(k  ))).or.
     &              ((dx2.eq.0.0).and.(Yo.ge.Yb(k+1)))) then
              inc=1
            elseif ((dx1*dx2.gt.0.0).and.             ! See Note 1
     &              ((Xb(k+1)-Xb(k))*dxy.ge.0.0)) then
              inc=2
            endif
            if (Xb(k+1).gt.Xb(k)) then
              crossings=crossings+inc
            else
              crossings=crossings-inc
            endif
          endif
        enddo
      enddo
!
!  Determine if point (Xo,Yo) is inside of closed polygon.
!
  10  if (crossings.eq.0) then
        inside=.false.
      else
        inside=.true.
      endif
      return
      end
