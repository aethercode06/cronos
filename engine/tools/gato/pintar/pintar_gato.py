import numpy as np, json
from PIL import Image
from scipy import ndimage
N=2048
P=np.load('/tmp/ovg/cuerpo_P.npy'); B=np.load('/tmp/ovg/cuerpo_B.npy')
info=json.load(open('/tmp/ovg/cuerpo_info.json')); nombres=info['nombres']; H={k:np.array(v) for k,v in info['huesos'].items()}
L=np.load('/tmp/ovg/cara3_L.npy'); ML=np.load('/tmp/ovg/cara3_M.npy')>0
zon=np.load('/tmp/ovg/zonas.npy'); ojo,nariz,lengua,oreja=zon
rng=np.random.default_rng(11)
def suave(v,a,b): return np.clip((v-a)/(b-a),0,1)
def ruido(s,amp):
    r=ndimage.gaussian_filter(rng.normal(0,1,(N,N)),s); return r/(r.std()+1e-9)*amp
cat=np.full((N,N),-1)
grupo={}
for i,n in enumerate(nombres):
    if n.startswith('tail'): grupo[i]=2
    elif any(n.startswith(k) for k in ('hip_','leg_','foot_','claw_','Helper')): grupo[i]=1
    elif any(n.startswith(k) for k in ('head','mouth','ear','eyelid','mustache','tongue')): grupo[i]=3
    elif n.startswith('neck'): grupo[i]=4
    else: grupo[i]=0
valido=B>=0
for i,g in grupo.items(): cat[B==i]=g
x,y,z=P[...,0],P[...,1],P[...,2]
# colores del gato de la foto
oscuro=np.array([64,50,37.]); medio=np.array([132,116,96.]); claro=np.array([200,188,166.])
n1=ruido(1.0,10)+ruido(5,8)
col=medio[None,None,:]+n1[...,None]*np.array([1,0.9,0.8])
# bordes rotos y vetas del pelo: el borde de cada raya se deshilacha en mechones y su fuerza varía
def nrm(a): return a/(a.std()+1e-9)
vet_f=nrm(ndimage.gaussian_filter(rng.normal(0,1,(N,N)),(0.7,2.5)))
vet_g=nrm(ndimage.gaussian_filter(rng.normal(0,1,(N,N)),(1.5,5.0)))
var_l=nrm(ndimage.gaussian_filter(rng.normal(0,1,(N,N)),18))
def mezcla(mf,c):
    global col
    a=np.clip(mf,0,1)
    a=np.clip(a+0.25*vet_f*a*(1-a)*4+0.08*vet_g*a,0,1)                # deshilachado en el borde
    a=a*np.clip(0.85+0.12*var_l,0.55,1.0)                              # unas rayas más marcadas que otras
    tic=np.clip(0.95+0.12*vet_f,0.7,1.2)[...,None]                    # pelos con la punta clara dentro de la raya
    destino=np.array(c)[None,None,:]*tic
    col=col*(1-a[...,None])+destino*a[...,None]
# --- tronco: rayas verticales finas (atigrado «mackerel») desde una línea oscura en el lomo
esp=[H[n][0] for n in ['tail_01_08','Spine_base_04','spine_03_05','spine_02_06','spine_01_07','spine_04_021','spine_05_022','neck_023']]
esp=np.array(sorted(esp,key=lambda p:-p[1]))
# eje del cuerpo sacado de la propia superficie: centro entre lo más alto y lo más bajo de cada rebanada
tor0=(cat==0)|(cat==4)
yv=y[tor0]; zv=z[tor0]; xv=x[tor0]
bins=np.linspace(yv.min(),yv.max(),60); cy=[];cz=[];cx=[]
for i in range(len(bins)-1):
    m=(yv>=bins[i])&(yv<bins[i+1])
    if m.sum()>50:
        cy.append((bins[i]+bins[i+1])/2); cz.append((np.percentile(zv[m],98)+np.percentile(zv[m],2))/2); cx.append(np.median(xv[m]))
cy=np.array(cy); o=np.argsort(cy)
zs=np.interp(y, cy[o], np.array(cz)[o]); xs=np.interp(y, cy[o], np.array(cx)[o])
dx=x-xs; dz=z-zs; th=np.degrees(np.arctan2(np.abs(dx),dz))
tronco=(cat==0)|(cat==4)
yc=H['neck_023'][0][1]
cerca_cuello=(1-suave(y-yc,0.02,0.07))*(1-suave(th,70,95))   # lomo junto al cuello: rayas a lo largo, no de través
fase=y/0.03+0.25*np.sin(np.radians(th)*2.0+y*40)+ruido(14,0.12)+ruido(40,0.2)
raya=np.cos(2*np.pi*fase)*0.5+0.5
# las rayas se cortan a trozos (como en los atigrados de verdad)
raya=raya*np.clip(0.85+ruido(9,0.35),0,1)
mezcla(tronco*suave(raya,0.52,0.86)*(1-suave(th,95,125))*(1-cerca_cuello)*0.9,oscuro)
largas=np.cos((dx+ruido(10,0.0015))/0.0045*np.pi)*0.5+0.5
mezcla(tronco*cerca_cuello*suave(largas,0.6,0.9)*0.85,oscuro)
mezcla(tronco*(1-suave(th,8,16))*0.85,oscuro)                       # línea del lomo
mezcla(tronco*suave(th,115,140)*0.75,claro)                          # vientre claro
mezcla(tronco*suave(th,120,140)*suave(ruido(4,1),0.7,1.1)*0.5,oscuro)   # manchitas en la tripa
# --- patas: bandas horizontales, más claras por dentro y en las manos
patas=cat==1
banda=np.cos(2*np.pi*(z/0.034+ruido(10,0.35)+0.3*np.sin(x*90)))*0.5+0.5
banda=banda*np.clip(0.8+ruido(8,0.4),0,1)
mezcla(patas*suave(banda,0.6,0.9)*suave(z,0.04,0.07)*0.6,oscuro)
mezcla(patas*(1-suave(z,0.015,0.035))*0.5,claro)
# --- cola: anillos y punta oscura
cola=cat==2
tb=[H['tail_0%d_%s'%(i,s)] for i,s in [(1,'08'),(2,'00'),(3,'09'),(4,'010'),(5,'011'),(6,'012')]]
largo=np.zeros((N,N)); mejor=np.full((N,N),1e9)
acum=0.0
for (a,b) in tb:
    seg=b-a; l=np.linalg.norm(seg)+1e-9
    t=np.clip(((P-a)@seg)/l**2,0,1); d=np.linalg.norm(P-(a+t[...,None]*seg),axis=-1)
    m=d<mejor; mejor[m]=d[m]; largo[m]=acum+t[m]*l; acum+=l
anillo=np.cos(2*np.pi*largo/0.035)*0.5+0.5
mezcla(cola*suave(anillo,0.48,0.84)*0.9,oscuro)
mezcla(cola*suave(largo,acum-0.04,acum-0.02)*0.95,oscuro)
# --- cabeza (lados y detrás), continuando la cara de la foto
cab=((cat==3)|(cat==4))&ML
lx,ly,lz=L[...,0],L[...,1],L[...,2]; ax=np.abs(lx)
coron=np.cos((lx+ruido(10,0.0015))/0.0045*np.pi)*0.5+0.5
mezcla(cab*suave(ly,-0.005,0.01)*suave(-lz,0.0,0.02)*suave(coron,0.6,0.9)*0.9,oscuro)   # rayas de la frente hacia la nuca
ln=np.abs(np.mod(ly+0.3*(ax-0.02)+ruido(10,0.0008),0.011)-0.0055)
mezcla(cab*suave(ax,0.026,0.034)*suave(ly,-0.032,-0.024)*(1-suave(ly,0.004,0.01))*(1-suave(ln,0.0011,0.0022))*0.9,oscuro)  # líneas de la mejilla
mezcla(cab*suave(-ly,0.03,0.04)*(1-suave(ax,0.02,0.03))*0.7,claro)     # garganta clara
# collares en el pecho
pecho=((cat==4)|(cat==0))&(th>90)&(y<H['neck_023'][0][1]+0.06)
dcab=np.linalg.norm(P-H['head_024'][0],axis=-1)
coll=np.cos(2*np.pi*dcab/0.022)*0.5+0.5
mezcla(pecho*suave(coll,0.7,0.88)*0.6,oscuro)
# orejas: color de pelo con el borde oscuro
col[oreja]=(medio*0.85)[None,:]+rng.normal(0,9,(oreja.sum(),1))
vetas=ndimage.gaussian_filter(rng.normal(0,1,(N,N)),(0.6,3.0))*12
col=col+vetas[...,None]
# --- cara: foto proyectada encima
foto=np.asarray(Image.open('/tmp/foto_gato/cara_sin_ojos.jpg').convert('RGB')).astype(float); FH,FW=foto.shape[:2]
u=356.0+lx*5046.0; v=578.0-ly*5046.0*0.88
dentro=ML&(u>=0)&(u<FW-1)&(v>=0)&(v<FH-1)
mu=np.zeros((N,N,3))
for c in range(3): mu[...,c]=ndimage.map_coordinates(foto[...,c],[np.clip(v,0,FH-1.001),np.clip(u,0,FW-1.001)],order=1)
w=dentro*suave(lz,-0.055,-0.03)*(1-suave(ax,0.042,0.056))
w=ndimage.gaussian_filter(w.astype(float),4)*dentro
col=col*(1-w[...,None])+mu*w[...,None]
# piezas especiales
def pinta(mask,c,a=8):
    global col
    col[mask]=np.array(c)[None,:]+rng.normal(0,a,(mask.sum(),1))
pinta(nariz,(178,108,96)); pinta(lengua,(170,80,85))
# rellenar texeles sin geometría (márgenes) con el vecino más cercano
ok=valido|ojo|nariz|lengua
idx=ndimage.distance_transform_edt(~ok,return_distances=False,return_indices=True)
col=col[idx[0],idx[1]]
# --- ojos: iris verde oliva y dorado, pupila en rendija fina
cu,cv=0.8640,0.0500; R=0.026
yy,xx=np.mgrid[0:N,0:N]; uu=xx/N; vv=1-yy/N
du=(uu-cu)/R; dvv=(vv-cv)/R; r=np.sqrt(du*du+dvv*dvv); ang=np.arctan2(dvv,du)
fib=np.zeros((N,N)); r2=np.random.default_rng(9)
for k,(f,a) in enumerate([(23,0.35),(57,0.25),(131,0.2)]):
    fib+=a*(np.sin(ang*f+r2.random()*6.28+np.sin(r*9+k)*0.6)*0.5+0.5)
oro=np.array([128,112,46.]); oliva=np.array([78,90,36.])
t=np.clip((r-0.18)/0.8,0,1)[...,None]
iris=(oro*(1-t)+oliva*t)*(0.6+0.65*fib[...,None])+ndimage.gaussian_filter(r2.normal(0,1,(N,N)),1.5)[...,None]*12
iris=iris*(1-0.7*np.clip((r-0.86)/0.12,0,1))[...,None]
iris[r>1.0]=(18,16,10)
borde=np.sqrt((du/0.075)**2+(dvv/0.8)**2)<1.0
pup=np.sqrt((du/0.045)**2+(dvv/0.76)**2)<1.0
iris[borde]=iris[borde]*0.6
iris[pup]=(4,4,4)
col[ojo]=iris[ojo]
Image.fromarray(col.clip(0,255).astype(np.uint8)).save('/home/claude/cronos/engine/zarek/fauna/gato_pelo.jpg',quality=93)
print("PINTADO OK")
