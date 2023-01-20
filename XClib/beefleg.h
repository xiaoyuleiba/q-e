#ifndef beefleg_h
#define beefleg_h 1

#define PACKAGE "libbeef"
#define VERSION "0.1.2"

#define nsamples 2000

#define nmax 30

extern void dgemv_(const char *, const int *, const int *, const double *,
    double *, const int *, double *, const int *, const double *, double *,
    const int *);
#pragma acc routine (dgemv_) seq

#pragma acc routine seq
double ddot1(double v[], double u[], int n)
{
    double result = 0.0;
    int i = 0;
    for (i = 0; i < n; i++)
        result += v[i]*u[i];
    return result;
}

extern double ddot_(const int *, double *, const int *, double *, const int *);

//beef exchange enhancement factor legendre polynomial coefficients
static double mi[nmax] = {
 1.516501714304992365356,
 0.441353209874497942611,
-0.091821352411060291887,
-0.023527543314744041314,
 0.034188284548603550816,
 0.002411870075717384172,
-0.014163813515916020766,
 0.000697589558149178113,
 0.009859205136982565273,
-0.006737855050935187551,
-0.001573330824338589097,
 0.005036146253345903309,
-0.002569472452841069059,
-0.000987495397608761146,
 0.002033722894696920677,
-0.000801871884834044583,
-0.000668807872347525591,
 0.001030936331268264214,
-0.000367383865990214423,
-0.000421363539352619543,
 0.000576160799160517858,
-0.000083465037349510408,
-0.000445844758523195788,
 0.000460129009232047457,
-0.000005231775398304339,
-0.000423957047149510404,
 0.000375019067938866537,
 0.000021149381251344578,
-0.000190491156503997170,
 0.000073843624209823442
};
#pragma acc declare copyin (mi)

//LDA & PBE correlation fractions used in beef-vdw xc
#define beefldacfrac 0.600166476948828631066
#define beefpbecfrac (1.-beefldacfrac)


// beefmat * v = beefcoeff
// v: random (normal distr.) vector of length nmax+1
static double beefmat[] = {
  -2.7893711480032735e-01,  -8.6580724524194852e-02,  -5.5855907920886121e-02,
  -3.3705005058645578e-02,  -4.3991742039673903e-02,  -2.4503491855613693e-02,
  -1.3276193914397489e-02,  -1.0509981726996720e-02,   4.2736634878270653e-04,
  -4.9364956797540301e-04,  -1.6134327119866773e-05,   3.4041925565998549e-04,
   4.2194739762228741e-04,   3.9977584934996758e-04,   1.1522770556196138e-04,
  -5.2518450332638647e-04,  -6.8117173319719984e-04,   2.0498699215888136e-04,
   4.0709718001654695e-04,  -3.1397756373086392e-04,  -6.0280544285656027e-05,
   3.3690663944239876e-05,  -8.7385100446171526e-05,   1.5545027014986438e-04,
   2.7350091678557105e-04,  -2.9477110266707567e-04,  -5.5111864348780239e-04,
  -1.9845827344304281e-06,  -5.5546346992523670e-07,   1.5757159312984489e-09,
  -9.8638360313498823e-10,  -5.6208383185068933e-01,   2.2379503986741371e-02,
  -5.0188674858065566e-02,  -1.0302738542444243e-02,   3.0842482402716567e-03,
   7.9398824949748013e-03,   1.0555998187519086e-02,   1.3916427746131796e-02,
   1.7298034502763783e-03,  -5.8169770527605202e-04,   4.9364929282124325e-04,
  -4.4290949121031880e-04,  -3.9198121318981879e-04,  -3.6534622625584713e-04,
  -4.7114114975009910e-04,  -2.4624251970801044e-04,   1.7073071859719576e-04,
   2.0139877514473921e-04,  -1.3423791911459609e-03,   9.9452128430699261e-04,
   2.8066850900814681e-04,  -2.5321027319004011e-04,   1.4191449559300789e-04,
  -2.5212971013654833e-04,  -4.3474684754492607e-04,   4.6639558737092136e-04,
   8.6407197243737791e-04,   2.6613581886016500e-06,   5.9459265456201591e-07,
  -2.1667614837265335e-09,   1.8987772398720476e-09,  -4.1889825595060054e-01,
   8.5309440012684659e-02,   8.2089214257576273e-02,   2.1077454514367565e-02,
   2.4532065239845659e-02,   7.4593299022751702e-03,  -8.7517164279600317e-04,
  -7.5265340074405305e-03,  -2.5422677040271217e-03,   1.9258113062046427e-03,
  -1.4277299038031868e-03,   1.1632400701295784e-03,   7.7905784582151959e-04,
   7.1923875622523117e-04,   1.1434833169743359e-03,   1.2109589432120641e-03,
   3.7371827694673783e-04,  -6.7100742746982825e-04,   2.0114487626275396e-03,
  -1.3549460104091665e-03,  -3.9362157100724109e-04,   3.7367806138690598e-04,
  -1.8998730194510536e-04,   3.1812219820918941e-04,   5.1233069841357781e-04,
  -5.4519175224189951e-04,  -1.0076338494328359e-03,  -2.6644162301442129e-06,
  -5.5425012262767719e-07,   2.0811491412188100e-09,  -1.0854717505095305e-08,
  -7.8070096027212280e-02,   1.5779809309447619e-03,   1.6547556985414585e-01,
  -1.3284202027172546e-02,  -4.8425651568221604e-03,  -1.5820217046914831e-02,
  -8.3911788548852520e-03,  -9.8708341526036868e-03,   1.9755560754605148e-03,
  -1.4412634043633693e-03,   2.5726826620675299e-03,  -1.5774278285877145e-03,
  -1.6040605215626427e-03,  -9.9797875806281093e-04,  -1.6266596812565389e-03,
  -1.3222744001110936e-03,  -5.5977328518908812e-04,   6.7762959885338150e-04,
  -1.6052185640557444e-03,   7.9066006345622562e-04,   2.7398130030301674e-04,
  -1.4701727220069440e-04,   1.8423874587621713e-04,  -3.2444289888527587e-04,
  -4.2892623856473176e-04,   4.6193135460255924e-04,   8.4044927357011508e-04,
   2.5615438451876899e-06,  -5.1314624282347763e-07,   2.8785391639650792e-08,
   3.4633391551776865e-09,   7.4241087552789436e-02,  -5.4280040120440022e-03,
   6.5534412833281500e-02,  -7.3676789884596569e-02,   4.9126066596337937e-04,
  -6.3741847170612764e-03,   1.8022920362862328e-02,   1.8147438420912709e-02,
   5.1281518861036367e-03,   1.5643329785525021e-03,  -3.7674334940365298e-05,
   1.9161460751596674e-03,   5.1303002399607958e-04,   1.1737495095273077e-03,
   2.7424831860945863e-04,   2.8929440491493800e-04,  -1.3643930832243434e-04,
  -3.8451058499636436e-04,  -1.6446493569519672e-04,   2.8198101717418872e-04,
   2.6836258430682717e-04,  -3.6245004889293744e-04,  -2.7038853806751870e-04,
   2.6824785565116667e-04,   3.4596717548757025e-04,  -3.3476584292450472e-04,
  -6.2707939650082545e-04,   1.6303349067490777e-06,  -5.3243973391468833e-07,
   9.8897384913597132e-10,  -1.1961348316752441e-07,   1.9219539790640294e-02,
  -2.0206764138287829e-04,  -5.1969726886217447e-02,  -5.1327669591491869e-02,
   3.7207131447838271e-02,  -9.1864376240948491e-03,   4.0521588009745941e-03,
  -1.9708740524219115e-02,  -1.5528257052606061e-04,   5.5272314173948405e-03,
   3.6065107786608893e-04,   2.2921209578475239e-03,  -6.0493119937173306e-04,
   1.3264010830068790e-03,   1.1925154671001486e-03,   2.5367108496124960e-03,
   2.0471466747371895e-04,  -1.0084615091179223e-03,   2.0269870158526730e-03,
  -1.8142343224067773e-03,  -3.1916624486206900e-04,   1.0899323113728922e-03,
   1.5977194189760289e-04,  -3.6993982697979287e-04,  -2.8095429889228639e-04,
   3.3673412008212799e-04,   5.3016256566782382e-04,   2.2603641905826421e-06,
  -6.0162376060668507e-06,   2.0626271307694735e-07,   2.7080875890664975e-10,
  -1.9932513600214176e-02,  -3.1590139025144408e-03,  -4.1290926781928680e-02,
   2.2930887771390233e-02,   2.8588480718176067e-02,  -2.5422538807935227e-02,
   7.4291651267536559e-03,  -5.6441743796061304e-03,   9.6583047441454531e-03,
   2.4324308684833340e-03,   5.3063140357734774e-03,   6.1327502623585652e-04,
  -3.3301168451738139e-03,  -1.8166489805542909e-04,  -4.2805082728751571e-03,
  -2.7235276457503932e-03,  -1.2671126744029327e-03,   3.3085897019266428e-04,
  -3.7988540725469797e-03,   1.9997662400812392e-03,   1.2349981809226202e-03,
  -1.3462418114106411e-03,  -5.3437809436454619e-04,   2.4103065487655935e-04,
   3.4813005143659336e-04,  -2.3243343778689025e-04,  -4.5159874040786652e-04,
   1.5119074547806086e-05,  -6.9011025175958165e-07,   2.3330273843525182e-09,
  -5.3842762631498313e-07,   4.3011798669764258e-04,   9.9552785066539138e-04,
   1.6367943477601170e-02,   4.2785050543760354e-02,  -2.0452568930084115e-02,
  -1.9227084404651550e-02,   1.4373130724756761e-02,   5.7276357414483758e-03,
   1.2758307452167408e-02,   3.2112729756378741e-03,   5.4991197676025035e-03,
   3.2296047342698880e-03,  -2.1286546465503209e-03,   2.9476536066769593e-03,
   1.0201559844743992e-03,   3.2954854849929749e-03,  -1.1813139734199577e-03,
  -1.4174365268660759e-03,   2.5658999230135306e-03,  -2.9526732455200390e-03,
  -9.7004938493557751e-05,   1.7437271881877081e-03,   5.9754565134489387e-05,
  -6.0036116600961198e-04,  -1.3230631539389915e-04,   2.6028153195231722e-04,
   1.6677911152304927e-04,   1.3884201313790570e-06,  -2.2530742330382744e-05,
   7.3805127855484125e-07,  -5.8273323257104446e-10,   4.9290906772224263e-03,
   3.0610869932292733e-03,   1.4313796146577058e-02,   4.8181769157442842e-04,
  -2.5982977487858137e-02,   2.4348378769669884e-02,   9.0510010545148799e-03,
  -1.3516528967376500e-02,  -1.8726098827207454e-03,   1.2390557446126603e-02,
  -9.1227025683008613e-04,   7.0364465776508378e-03,  -1.4088125053006069e-03,
   3.4067454992656385e-03,  -1.2603784560760989e-03,   2.1812385869284081e-03,
   2.1084324466647831e-05,  -2.2698924902178428e-03,  -2.2226191104179477e-03,
   1.3339278571527775e-03,   1.8204956012944679e-03,  -1.3446791863853983e-03,
  -9.9909759668189119e-04,   2.3435102450791270e-04,   2.5254141307444526e-04,
   1.1134484630654041e-04,   1.5286842865445637e-04,   4.7770176810314048e-05,
  -3.0570574206400900e-09,  -1.8280421027556346e-09,  -1.5932607092782039e-06,
  -2.8110227717260271e-03,  -3.1231467242703289e-03,  -7.5951163296362686e-03,
  -2.1260181962774405e-02,   1.4990600431812426e-03,   2.6948085160114123e-02,
  -1.3125993744515290e-02,   2.5328095875940654e-03,   5.1350312584983243e-03,
  -1.6143115098225704e-03,   8.1287346936694729e-03,  -3.6059174026760633e-04,
  -5.6502508444833946e-03,   6.6779252331724626e-04,  -5.0326662554609552e-03,
  -1.8088213195257283e-03,  -3.7431045571209194e-03,   8.3448014976049661e-05,
  -9.8614380505414540e-04,  -2.6401009553883316e-03,   5.9341419291161312e-04,
   2.0739686828981424e-03,  -5.9797634333075985e-05,  -1.0872087775937360e-03,
   8.0967213780402546e-05,   1.7373279075753355e-04,  -3.9850700378931683e-04,
   4.7334970806959295e-07,  -5.5985173946584438e-05,   1.9031863901026922e-06,
   3.4027792381324185e-09,  -3.1280359588473967e-04,   5.0300486943160054e-04,
  -2.8683399135020489e-03,  -1.2008277866989911e-03,   1.4099834934249001e-02,
  -9.5346660390286091e-03,  -2.3740581166392327e-02,   1.3188455344687964e-02,
  -1.4460548177748710e-03,  -4.2037545782719751e-03,   1.4670013169385359e-03,
   1.9671337767890882e-03,  -1.3025084329530438e-03,   3.1550217754350482e-03,
   8.6233628968752322e-04,   5.0634050666416948e-03,   6.8840641553373526e-04,
  -3.8643121063023107e-03,   2.7532585912541218e-04,  -2.1002860074291254e-04,
   2.2359939934659696e-03,  -1.3840652254543024e-03,  -1.6763605667005842e-03,
   3.7098662305387614e-04,   5.0284264148414009e-04,   2.1342825683299952e-04,
   2.9361015559854043e-04,   1.0312347464059402e-04,   2.3987071391277137e-07,
  -2.9324654172546502e-09,  -3.6710510430712760e-06,   1.3368121380154261e-03,
   1.4877365013506760e-03,   4.2337278687268184e-03,   8.9532297499984297e-03,
   3.2367419938850294e-03,  -1.6509842616506145e-02,   4.2662388175525008e-03,
   5.1287520687677045e-03,  -1.9318765281838401e-02,   1.2840401098951606e-03,
  -8.9041973081194960e-03,   2.5805526816426402e-03,   1.9426554396526879e-03,
   2.1383002718137539e-03,  -1.1198522043181984e-03,  -4.5860467230069113e-04,
  -3.0213216077694940e-03,   4.3803366522670416e-05,  -2.8955020910217968e-03,
  -7.6188510148852908e-04,   1.4406655488350538e-03,   1.9913160267415798e-03,
  -1.9574454921368270e-04,  -1.6206278579913766e-03,  -4.2397416300276465e-05,
   5.2668955401950952e-04,  -3.1473706074703137e-04,   1.1305854764916919e-06,
  -1.1025780419487959e-04,   4.0231475478550114e-06,   7.4448742155610599e-10,
  -5.7542806536456988e-04,  -1.3962047676911223e-03,  -7.7910733149695881e-04,
  -2.0293445396823073e-03,  -8.0584277113443983e-03,   9.2561802708384982e-04,
   1.8365141864082186e-02,  -8.0855208176669503e-03,  -5.9567473717600629e-03,
  -1.0813373009694597e-02,  -5.3648971000046697e-04,  -8.0483569657769771e-03,
  -1.1786907195179093e-03,  -3.4585921438278584e-03,  -2.8048252033714858e-03,
  -1.3298062340290390e-03,   1.2174093629560551e-04,  -1.8509549096989374e-03,
   1.7726580693748909e-03,  -2.4617807425807501e-03,   1.3327542858251992e-03,
  -4.2946375589953463e-04,  -1.9574487953845573e-03,   3.0631609184529331e-04,
   8.7082976920211514e-04,   2.2107939301901358e-04,   2.5002382690157145e-04,
   1.8567319491871292e-04,   1.0950042045068506e-06,  -1.4260985857055198e-09,
  -7.2146860148408335e-06,  -2.6604588926341721e-04,   1.1930752380141212e-04,
  -1.5904049684056826e-03,  -2.5464828659123254e-03,   2.4562492448205900e-04,
   8.2137273331999595e-03,   7.2372122281901669e-04,  -8.0305782586859338e-03,
   1.6461891735701385e-02,  -7.4726404087930879e-03,  -3.3308999994364785e-03,
  -3.8605578571737301e-03,   5.1939018263187650e-03,  -7.4783594984583011e-04,
   4.7329846259356904e-03,   2.5576434013004864e-03,   1.3184094162786905e-03,
  -2.2296241792944498e-04,  -2.1461375216242336e-03,   1.7064815869658875e-03,
   1.6793057923813973e-03,   5.9966950380175297e-04,  -4.2596934644769784e-04,
  -1.6262797376181580e-03,   5.5748735064045878e-06,   7.1301762682680220e-04,
  -5.4170894930021419e-04,   4.0926971253201973e-07,  -1.8615721232857828e-04,
   7.4644639020998914e-06,  -8.8402142176878236e-10,   3.1357190287392180e-04,
   7.9597866907847245e-04,   1.2242374484315670e-03,   2.2432983924643968e-03,
   3.7360392631435374e-03,  -1.8346315422847415e-04,  -8.9447986235832600e-03,
   5.1170003773556103e-03,   9.8612943651755561e-03,   1.2982450375216243e-02,
  -5.9568539025605695e-03,   8.8293572499739410e-04,   5.2355853108957354e-03,
  -2.5140777372805192e-03,   9.4718806147847093e-04,  -4.8498469710574546e-03,
  -1.1455902067634613e-03,   2.5278263036861127e-03,   8.7518557957694308e-04,
  -1.4988946837090279e-03,  -1.6587461108646788e-04,   5.3010146581652820e-04,
  -1.4769598311308706e-03,   1.4099290153743994e-04,   1.0210377105148046e-03,
   3.4652152930751690e-04,   4.2894782721634181e-04,   2.8827160262158191e-04,
   1.9605575118429994e-06,  -2.6869941750589450e-09,  -1.2686959481251205e-05,
   6.2118690045315475e-05,  -6.9266581150996000e-04,   6.5114347606650224e-05,
  -4.6299515842343356e-04,  -2.6341253451073600e-03,  -4.1145044177758354e-03,
  -1.3119014396461980e-03,   4.3517571287416384e-03,  -9.0629517469005098e-03,
   1.0876617207688946e-02,   9.5074167710495622e-03,  -2.5681139285186438e-03,
  -2.5209727209737111e-03,  -4.9645213357883220e-03,   5.0815058814798492e-04,
  -9.0717430454276401e-04,   4.8990052765759216e-03,  -3.5042177275447457e-04,
   2.2376237780211885e-03,   1.3560371613952321e-03,  -3.8279814357953214e-05,
  -6.5921630983060725e-04,  -3.2119768671761486e-04,  -1.1111879074490862e-03,
  -4.4176453802506131e-05,   8.8890690397482855e-04,  -5.3043155420778626e-04,
   1.6971000247480230e-06,  -2.7469671290871004e-04,   1.2580575273862472e-05,
  -9.0683882200211484e-10,  -2.1359674139973282e-04,  -4.0018169945925451e-05,
  -5.7750576026077195e-04,  -6.4180711343731465e-04,   2.0302930490348061e-04,
   1.6351119341946150e-03,   3.9857022191808573e-03,  -2.7095680824841474e-03,
  -7.2175363048520022e-03,  -7.8163708147656330e-03,   1.0173365767109905e-02,
   6.1359344279036691e-03,  -6.9549366450624847e-04,   2.6363883393387536e-03,
   4.5181771577114923e-03,   7.7785558025172258e-04,  -4.3496217454422854e-05,
   4.1922339149713331e-03,  -1.4074237424951059e-03,   1.5659520740856784e-03,
  -1.6703844903901651e-03,   9.5438736622087395e-04,  -1.6173074048544354e-04,
   3.9478874219593374e-05,   1.1039556457800360e-03,   1.9664021921996113e-04,
   1.6363589600986673e-04,   3.9163960761265886e-04,   2.3447662266569635e-06,
  -1.4333073815630597e-09,  -2.0502087244552265e-05,   2.2157620440394014e-06,
   6.6750032941751845e-04,   2.9172971033746323e-04,   7.9020703940250027e-04,
   1.5587178279708612e-03,   1.1620151775589892e-03,   6.2240236463069490e-05,
  -1.3811367430065333e-03,   4.3748403598123124e-03,  -8.6101227336660233e-03,
  -7.4310448077580761e-03,   8.9021093046344479e-03,  -3.0274072215419764e-03,
   3.1660132630635129e-03,  -3.1477368993255051e-03,  -2.9597559782082706e-03,
  -2.1155096110190175e-04,   7.7091015293960735e-04,   3.3072902087843219e-03,
   4.6210608863975580e-04,  -1.6061209355446389e-03,  -2.0187418413509014e-03,
  -6.4876860796269075e-06,   1.6522153071454654e-04,  -1.6726296267198875e-04,
   9.2431208321653788e-04,  -2.2287583148094444e-04,   2.5511431088727062e-06,
  -3.6039970881849361e-04,   1.9688235979535197e-05,  -3.7457192432901044e-09,
   2.5807620945812000e-04,  -7.2244544324433571e-04,   1.0790368127414874e-04,
  -4.1760238948185046e-04,  -1.7448269612268148e-03,  -1.8016710613760290e-03,
  -1.5859335586748617e-03,   1.4175473106720754e-03,   3.3556271404118544e-03,
   3.5652147444237134e-03,  -8.8148399469076526e-03,  -6.3781804659885089e-03,
  -6.8481681048368718e-03,   1.0276546730352168e-03,  -3.5612851303833347e-03,
   3.8919808800686800e-03,   1.9980897223815432e-03,  -1.2128395513872237e-03,
  -5.8259865297205136e-04,   1.8850909766925110e-03,  -2.0200258452286943e-03,
   1.0659318264400290e-03,   1.6146290527533289e-03,  -2.5678274788187096e-04,
   6.8608350772634814e-04,   4.4674639554755061e-05,  -2.3738712621118025e-05,
   4.6909565196073496e-04,   3.2750985126758742e-06,  -1.0508877359882054e-09,
  -3.0995955086127838e-05,  -2.6090295873073399e-04,   2.2593157068985373e-04,
  -2.5873340354153014e-04,  -1.0432034069002237e-04,   5.3396230602151349e-04,
   8.3941703085044705e-04,   7.7616674863855578e-04,  -7.3565108539809835e-05,
  -2.3655096266623783e-03,   4.8338632155411811e-03,   3.7305174303572204e-03,
  -9.4123048258186546e-03,   4.0467754114985001e-03,   4.1042735786481280e-03,
   4.5660113084445712e-04,   2.9056073274273363e-03,  -4.9773047112733606e-03,
   7.5914148822592612e-04,  -1.3672500116079960e-03,  -1.1515008332860619e-03,
  -1.5774145860636551e-03,  -1.3874200763924686e-03,   2.9523415504071265e-04,
   1.6475835121375531e-03,  -8.6718480733062874e-05,   4.5719257547222248e-04,
  -8.8416958937781763e-05,   2.5419846171150652e-06,  -4.1745943816031057e-04,
   2.9037338003440348e-05,  -4.8641001503932725e-09,  -3.3875340880671390e-06,
   3.8854434947631496e-04,   1.5255986580861542e-04,   4.4231876423827599e-04,
   8.5687765241308279e-04,   4.9705062382093303e-04,   7.8437184053581466e-05,
  -5.8370635976557955e-04,  -6.5015462417685062e-04,  -1.9275788771249507e-03,
   5.4025542446396813e-03,   3.7050329130392900e-03,   9.5337152347673010e-03,
  -1.8500719493484013e-03,  -2.5998770090829969e-03,  -1.7921763933910746e-03,
  -1.5070360642670615e-03,  -4.6225189534133604e-03,   9.6896548007970973e-04,
   1.9780464301734265e-04,   7.8226350391399229e-04,  -7.4948199490994564e-04,
   2.2162510831858499e-03,  -3.7065352470400629e-04,  -1.9080725631003573e-04,
  -5.1697784965698951e-05,  -5.6772926264705180e-05,   4.8008042025353599e-04,
   2.9689347658160229e-06,  -4.0508153712783222e-09,  -4.4376992450690561e-05,
   2.8656860643779843e-04,  -6.0723827461135922e-04,   8.9652701855479268e-05,
  -3.3722363780791357e-04,  -1.2273225745712776e-03,  -1.1208506603616873e-03,
  -5.7376759633318995e-04,   5.0470316291295603e-04,   1.1372295314039857e-03,
  -1.8742615395240399e-03,  -1.7699835210057207e-03,   6.4172581555616923e-03,
  -2.2641737523530618e-03,  -8.3905329914488857e-03,   1.1962776747535253e-03,
   1.1168936154126797e-03,   1.7441657118701060e-03,  -1.5880517854128917e-03,
  -3.3283970696354036e-03,  -1.9452225624805367e-03,   2.7709962173234177e-04,
   1.7334196123640587e-03,   4.8378489526356490e-04,   1.8299929821834237e-03,
   1.4411009104043159e-05,  -2.5608521367940406e-04,   1.3956561131376027e-04,
   3.8404496716179571e-06,  -4.1420194476987372e-04,   4.0763682598377557e-05,
  -4.3001030012746268e-09,  -3.2795025947796546e-04,   2.7837362859566109e-04,
  -2.5801815520712324e-04,  -7.6884800996573273e-05,   4.4699382189544756e-04,
   6.8551289269577612e-04,   6.0741397737702470e-04,  -1.8499524748852945e-05,
  -5.4196601279355773e-04,   1.3208939489178523e-03,  -2.5964000584312000e-03,
  -1.7336470429971179e-03,  -7.5603676752781131e-03,   2.9070149137429155e-04,
   6.4482227927468751e-03,  -2.1489444199310035e-03,  -1.4230490906760446e-03,
   1.8169764635181242e-03,   6.7983720224022826e-05,  -2.1561275597188445e-03,
   2.7260521253352332e-03,  -1.8300026665438493e-03,   5.4963459881875632e-04,
  -4.5219985324618448e-05,  -9.7394557008500474e-04,  -2.1933952472490118e-04,
  -2.2310319932044201e-04,   3.8834937158853952e-04,   1.9039628159021295e-06,
  -5.5536157089227886e-09,  -6.0675975477065685e-05,   9.3302639864854266e-05,
   2.3339579903288108e-04,   1.7775902384819042e-04,   3.4243433084381097e-04,
   5.5750335496336815e-04,   2.5233808615771091e-04,  -1.1281124813925308e-04,
  -3.4268677698185476e-04,  -8.3165051103961077e-05,   8.8429111750297617e-05,
   1.1803214341051613e-03,  -3.3597902952208895e-03,   8.2300563761220677e-04,
   7.7568191353945860e-03,  -2.1323883809726602e-04,  -4.5235513690711085e-03,
   3.3544646570372125e-03,  -1.8547392389106984e-04,   1.7056584504294026e-03,
   1.7389044210859308e-03,   2.5624656326692715e-03,   2.1075918064110007e-03,
   1.7655688651649145e-04,   2.4347639496794055e-04,   8.0341660812841874e-05,
  -8.6035464445300672e-04,   4.0853119890643127e-04,   3.1106201761768523e-06,
  -3.2463367641115013e-04,   5.4867873654193066e-05,  -7.1952746762362615e-09,
   2.0035305510703163e-04,  -4.1470564629065068e-04,   7.7757242307016758e-05,
  -2.0649053086643453e-04,  -8.1705094869878570e-04,  -7.7590949646469095e-04,
  -4.4764387897257323e-04,   2.4235976605899791e-04,   5.0719709556882437e-04,
  -6.0619460486065918e-04,   7.7723307065286659e-04,   9.7970695866240890e-04,
   4.4325535716739336e-03,   8.6565714933583399e-04,  -5.6874671538713886e-03,
   3.6369082580526703e-03,   3.9496935822962058e-03,   3.9128965494382630e-03,
  -6.2754528357869619e-04,  -1.1570007004839940e-03,  -3.3166553408609271e-04,
   5.4384291000910984e-04,  -1.8705788666701219e-03,   2.9405172845078166e-04,
  -1.2222588412306808e-03,  -2.2891603541204061e-04,  -2.1467092296314339e-04,
   1.7478332775632674e-04,   1.3972574343180186e-06,  -5.7279591476758486e-09,
  -7.9742615225032346e-05,  -3.0075798989147681e-04,   1.4118701101636561e-04,
  -2.4240631409222973e-04,  -1.1785201583561527e-04,   2.4193417610447515e-04,
   4.6523705060868783e-04,   4.9129251547784113e-04,   9.9916536450085264e-05,
  -4.1041593831106369e-04,   5.0541939579484883e-04,  -7.7438126257460419e-04,
   1.3270121215682937e-03,  -4.2642936680703606e-04,  -5.0811628681540644e-03,
  -1.2244180097435811e-03,   4.5000172726604943e-03,  -4.6485436804198947e-03,
   2.4095129398396579e-03,   2.6249577773794232e-03,   2.0560610805366521e-03,
   4.2673006136392647e-04,  -1.0417284476604593e-03,  -4.4756553523878279e-04,
  -1.7156599571386166e-03,   1.5837278146672791e-04,  -1.0292671007440847e-03,
   3.5034243358238187e-04,   9.3524701103512595e-07,  -1.3324582404794741e-04,
   7.1217236168440604e-05,  -8.4826920074820654e-09,   8.8487458676305089e-05,
   2.5411257464301760e-04,   1.1631330722711955e-04,   2.4706559772584943e-04,
   5.0363596168365393e-04,   3.2925334215437298e-04,   5.4865482297388669e-05,
  -2.4984731108154343e-04,  -1.5023316925162974e-04,   5.7089788276837070e-05,
   3.9200009487858244e-05,  -6.0053644013143307e-04,  -1.9471560296367080e-03,
  -8.0439039738820761e-04,   2.8398775343293813e-03,  -2.5148892944348586e-03,
  -3.4385946494612835e-03,  -4.3967414780182847e-03,   4.8062801167336061e-04,
   3.2538487861870366e-03,  -2.4653635511351106e-03,   1.6210813355552567e-03,
  -1.8960620163814548e-03,   2.9334053827329834e-04,  -4.6008176198270929e-04,
  -5.2750995834480166e-05,  -3.5881015258430354e-05,  -1.5733251013534650e-04,
  -8.0433630524953438e-07,  -9.3134893153291366e-09,  -1.0126700420616725e-04,
   1.3524438560090350e-04,  -2.3657150167652783e-04,   8.4063693464263644e-05,
  -7.3284196918286295e-05,  -4.5747684911547662e-04,  -4.9385229541419780e-04,
  -3.4615227602379921e-04,   7.6053373209164201e-05,   3.4515183198076101e-04,
  -3.4930928458053499e-04,   2.9241034735481098e-04,  -2.7639227986046247e-04,
   3.6654015848700347e-04,   2.4583473727325294e-03,   1.3808700892046131e-03,
  -2.2854206521655813e-03,   2.8668302261101726e-03,  -2.3837177410215723e-03,
  -3.2669763894858229e-03,  -3.1927275211167719e-03,  -3.2249104816820815e-03,
  -1.7758589472062628e-03,  -4.6211772345946937e-04,  -1.5913577025463228e-03,
   5.2209681324993251e-05,  -3.3172305063837123e-04,   9.3645090863664495e-05,
  -4.0531462102762323e-07,   1.5379696379095242e-04,   8.9553577540403740e-05,
  -8.3095679845718682e-09,  -7.7614312182869432e-05,  -6.9224510403129077e-05,
  -7.0511436907771101e-05,  -9.2092390003882744e-05,  -1.3108592128347423e-04,
  -5.2166463363986037e-05,   3.8189747222245900e-05,   9.7034215578165717e-05,
   6.6698289420144591e-06,   4.1465837932271208e-05,  -8.6491223894963871e-05,
   1.8599835598442636e-04,   4.5419293400123992e-04,   2.4637402659425338e-04,
  -6.6384442423605484e-04,   7.0859502436792013e-04,   1.0992380591874002e-03,
   1.4314937223341589e-03,  -1.4570501008170258e-04,  -1.3731334006113543e-03,
   1.2298515850134274e-03,  -8.9292439144695148e-04,   1.6314598205173117e-03,
  -2.6215137530695448e-04,   1.1695055548712869e-03,   2.1630290489579952e-04,
   2.0790865575842334e-04,  -5.6795284112210593e-04,  -3.6817519448666263e-06,
  -1.3232041203107141e-08,  -1.2483857322058414e-04,  -6.8648130614685716e-06,
   9.4884349344528113e-05,   2.8169710973816057e-06,   5.5314611665325722e-05,
   1.8193865910137160e-04,   1.6376627773798306e-04,   8.6804623936378438e-05,
  -5.8747038363387132e-05,  -1.0309325547777985e-04,   8.5655035651616525e-05,
  -3.9013644288256400e-05,  -2.9972201744199742e-06,  -1.4223835592234795e-04,
  -6.1728813484959516e-04,  -4.8730493463071016e-04,   5.0616799947066483e-04,
  -7.6210587996690783e-04,   7.8977404395214165e-04,   1.1085140504767312e-03,
   1.1732659695961691e-03,   1.5071570177655463e-03,   1.0707318594434011e-03,
   3.9653242216132148e-04,   1.4685549102334643e-03,  -1.3178963305750352e-04,
   1.0036937264612503e-03,  -3.8330969230438306e-04,  -4.6956191298802305e-06,
   5.0244872004260070e-04,   1.0955078418257361e-04,  -1.4102930471052401e-08,
   5.3903360902318162e-02,   4.5646784742740532e-01,  -2.3775359618348597e-02,
  -1.0804428280726967e-02,  -1.2685075587595527e-02,  -6.5186790847643755e-03,
  -2.6801719660519757e-03,  -1.0219114528977680e-03,   6.2601830432405575e-04,
  -5.0759231993347616e-04,   3.5935438417533216e-04,  -2.0299577991029813e-04,
  -1.1528037487456212e-04,  -8.6914308586454053e-05,  -2.3170116329541290e-04,
  -3.4162104059285499e-04,  -2.0297105465141889e-04,   1.6362554140599247e-04,
  -2.5010861768559074e-04,   1.3249006118439094e-04,   4.3449210292733832e-05,
  -4.5596513172512997e-05,   9.5088226421318060e-06,  -1.4531856486312905e-05,
  -1.3596189144146172e-05,   1.3812870532393629e-05,   2.4491439899588591e-05,
   2.8004467174549986e-08,  -1.8015504836958041e-08,   1.1727867063472466e-10,
   3.1916369403073135e-10
};


//Legendre polynomial calculation macros and functions

#define calcleg(x) { \
    L[1] = x; int i=0; \
    for(i=2;i<nmax;i++) \
	L[i] = 2.*(x)*L[i-1] - L[i-2] - ((x)*L[i-1] - L[i-2])/((double) i); \
}

#define calclegdleg(x) { \
    L[1] = x; int i=0;\
    for(i=2;i<nmax;i++) { \
	L[i] = 2.*(x)*L[i-1] - L[i-2] - ((x)*L[i-1] - L[i-2])/((double) i); \
	dL[i] = L[i-1]*((double) i) + dL[i-1]*(x); \
    } \
}

#define calcNleg(n,x) { \
    int i=0; \
    for(i=2;i<n+1;i++) \
	L[i] = 2.*(x)*L[i-1] - L[i-2] - ((x)*L[i-1] - L[i-2])/((double) i); \
}

#define calcNlegdleg(n,x) { \
    int i=0; \
    for(i=2;i<n+1;i++) { \
	L[i] = 2.*(x)*L[i-1] - L[i-2] - ((x)*L[i-1] - L[i-2])/((double) i); \
	dL[i] = L[i-1]*i + dL[i-1]*(x); \
    } \
}

#define defL(n) \
    static double L ## n (double x) { \
	double L[n+1]; \
	L[0] = 1.; \
	L[1] = x; \
	calcNleg(n,x); \
	return L[n]; \
    }

#define PRAGMA_ACC_ROUTINE _Pragma("acc routine seq")

#define defLdL(n) \
PRAGMA_ACC_ROUTINE \
    static void LdL ## n (double x, double *y, double *z) { \
	double L[n+1]; \
	double dL[n+1]; \
	L[0] = 1.; \
	L[1] = x; \
	dL[0] = 0.; \
	dL[1] = 1.; \
	calcNlegdleg(n,x); \
	*y = L[n]; \
	*z = dL[n]; \
    }


double L0(double x) {return 1.;}
double L1(double x) {return x;}
defL(2)
defL(3)
defL(4)
defL(5)
defL(6)
defL(7)
defL(8)
defL(9)
defL(10)
defL(11)
defL(12)
defL(13)
defL(14)
defL(15)
defL(16)
defL(17)
defL(18)
defL(19)
defL(20)
defL(21)
defL(22)
defL(23)
defL(24)
defL(25)
defL(26)
defL(27)
defL(28)
defL(29)

static double(*Ln[])(double) = {
    L0,
    L1,
    L2,
    L3,
    L4,
    L5,
    L6,
    L7,
    L8,
    L9,
    L10,
    L11,
    L12,
    L13,
    L14,
    L15,
    L16,
    L17,
    L18,
    L19,
    L20,
    L21,
    L22,
    L23,
    L24,
    L25,
    L26,
    L27,
    L28,
    L29
};

#pragma acc routine seq
static void LdL0(double x, double *y, double *z) {*y=1.; *z=0.;}
#pragma acc routine seq
static void LdL1(double x, double *y, double *z) {*y=x; *z=1.;}
defLdL(2)
defLdL(3)
defLdL(4)
defLdL(5)
defLdL(6)
defLdL(7)
defLdL(8)
defLdL(9)
defLdL(10)
defLdL(11)
defLdL(12)
defLdL(13)
defLdL(14)
defLdL(15)
defLdL(16)
defLdL(17)
defLdL(18)
defLdL(19)
defLdL(20)
defLdL(21)
defLdL(22)
defLdL(23)
defLdL(24)
defLdL(25)
defLdL(26)
defLdL(27)
defLdL(28)
defLdL(29)

static void(*LdLn[])(double,double *,double *) = {
    LdL0,
    LdL1,
    LdL2,
    LdL3,
    LdL4,
    LdL5,
    LdL6,
    LdL7,
    LdL8,
    LdL9,
    LdL10,
    LdL11,
    LdL12,
    LdL13,
    LdL14,
    LdL15,
    LdL16,
    LdL17,
    LdL18,
    LdL19,
    LdL20,
    LdL21,
    LdL22,
    LdL23,
    LdL24,
    LdL25,
    LdL26,
    LdL27,
    LdL28,
    LdL29
};

#pragma acc routine seq
static void LdLnACC(double t,double *fx,double *dl, int bo) {
    switch(bo) {
      case  0: LdL0(t  ,fx ,dl ); break;
      case  1: LdL1(t  ,fx ,dl ); break;
      case  2: LdL2(t  ,fx ,dl ); break;
      case  3: LdL3(t  ,fx ,dl ); break;
      case  4: LdL4(t  ,fx ,dl ); break;
      case  5: LdL5(t  ,fx ,dl ); break;
      case  6: LdL6(t  ,fx ,dl ); break;
      case  7: LdL7(t  ,fx ,dl ); break;
      case  8: LdL8(t  ,fx ,dl ); break;
      case  9: LdL9(t  ,fx ,dl ); break;
      case 10: LdL10(t ,fx ,dl ); break;
      case 11: LdL11(t ,fx ,dl ); break;
      case 12: LdL12(t ,fx ,dl ); break;
      case 13: LdL13(t ,fx ,dl ); break;
      case 14: LdL14(t ,fx ,dl ); break;
      case 15: LdL15(t ,fx ,dl ); break;
      case 16: LdL16(t ,fx ,dl ); break;
      case 17: LdL17(t ,fx ,dl ); break;
      case 18: LdL18(t ,fx ,dl ); break;
      case 19: LdL19(t ,fx ,dl ); break;
      case 20: LdL20(t ,fx ,dl ); break;
      case 21: LdL21(t ,fx ,dl ); break;
      case 22: LdL22(t ,fx ,dl ); break;
      case 23: LdL23(t ,fx ,dl ); break;
      case 24: LdL24(t ,fx ,dl ); break;
      case 25: LdL25(t ,fx ,dl ); break;
      case 26: LdL26(t ,fx ,dl ); break;
      case 27: LdL27(t ,fx ,dl ); break;
      case 28: LdL28(t ,fx ,dl ); break;
      case 29: LdL29(t ,fx ,dl ); break;
    }
}

// LDA and PBEc coefficients

//pix = 1./(2.*(3.*pi**2)**(1./3.))**2
#define pix 0.026121172985233605
//LDA exchange energy = r2e*rho**4/3
#define r2e (-0.73855876638202245)


#define defaultseed 1

//random number generation macros
#define unirandinc0() \
    ( ((double) random()) / ((double) RAND_MAX) )

#define unirandex0() \
    ( (1.+random()) / (1.+RAND_MAX) )

#define normrand() \
    ( sqrt(-2.*log(unirandex0())) * cos(M_PI*2.*unirandinc0()) )

// beeforder==-1 : calculate beefxc with standard expansion coefficients
// (is changed by beefsetmode_)
static int beeforder = -1;
#pragma acc declare copyin (beeforder)

//arrays holding current Legendre polynomials and derivatives
//static __thread double L[nmax] = {1.};
//static __thread double dL[nmax] = {0.,1.};

//static double L[nmax] = {1.};
//static double dL[nmax] = {0.,1.};

static inline double sq(double x) {return x*x;}

// beeftype is a switch set by beef_set_type
// which determines which version/type of beef is used
static int beeftype = 0;
#pragma acc declare copyin (beeftype)

#define output_spacing "     "
#define output_marker "**************************************************************************"

#endif
