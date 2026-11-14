class RiderDelivery {
  const RiderDelivery(this.name, this.assigned, this.delivered, this.onHold, this.target);
  final String name;
  final int assigned, delivered, onHold, target;
  int get delivering => assigned - delivered - onHold;
  double get percentDelivered => delivering <= 0 ? 100.0 : assigned == 0 ? 0.0 : delivered / assigned * 100;
  double get achievement => target == 0 ? 0 : delivered / target * 100;
}

class AgingEntry {
  const AgingEntry(this.rider, this.resi, this.account, this.days, this.attempts, this.status, this.reason, this.sizeType);
  final String rider, resi, account, status, reason, sizeType;
  final double days;
  final int attempts;
  String get kategori => days > 3 ? '>3 days' : '2–3 days';
}

class PreTripEntry {
  const PreTripEntry(this.name, this.type, this.status);
  final String name, type, status;
}

class DailyControlDemo {
  static const riders = <RiderDelivery>[
    RiderDelivery('MUHAMMAD WANDA ARYA', 77, 73, 4, 75),
    RiderDelivery('HALIMAN', 54, 53, 1, 75),
    RiderDelivery('ADRIAN KUSWONDO', 84, 72, 3, 75),
    RiderDelivery('RISFAL FADHILLAH', 96, 79, 17, 75),
    RiderDelivery('MARDIANSYAH', 57, 53, 4, 75),
    RiderDelivery('FIQI ARIANTO', 98, 94, 4, 110),
    RiderDelivery('TRI IRWAN', 78, 65, 11, 110),
    RiderDelivery('MUHAMMAD THORIQ LUBIS', 115, 106, 9, 110),
    RiderDelivery('ISMAIL', 115, 104, 4, 147),
    RiderDelivery('RENDI SAPUTRA', 180, 115, 3, 147),
  ];

  static const aging = <AgingEntry>[
    AgingEntry('ANDIKA','SPXDEMO0000001','NS Marketplace Standard',5.67,3,'LMHub_Received','Recipient reject','NON_BULKY'),
    AgingEntry('APRIL YANDI','SPXDEMO0000002','NS Marketplace Standard',6.50,2,'LMHub_Received','', 'NON_BULKY'),
    AgingEntry('DIKI HERMANSYAH','SPXDEMO0000003','Economy',3.39,2,'Delivering','Recipient unavailable for parcel','NON_BULKY'),
    AgingEntry('HALIMAN','SPXDEMO0000004','NS Marketplace Standard',3.51,1,'Delivering','Recipient reject','SEMI_BULKY'),
    AgingEntry('HAMDANI PULUNGAN','SPXDEMO0000005','Economy',3.39,1,'Delivering','Recipient reschedule','SEMI_BULKY'),
    AgingEntry('NEDI SAFITRI','SPXDEMO0000006','NS Marketplace Standard',5.47,1,'Delivering','Recipient reject','NON_BULKY'),
    AgingEntry('PRAMUJA','SPXDEMO0000007','NS Marketplace Standard',5.52,1,'Delivering','Recipient reject','NON_BULKY'),
    AgingEntry('RENDI SAPUTRA','SPXDEMO0000008','NS Economy',7.02,3,'Delivering','Recipient reject','NON_BULKY'),
    AgingEntry('RIZKI RAHMAT DANI','SPXDEMO0000009','Economy',4.63,2,'Delivered','','NON_BULKY'),
    AgingEntry('TRI IRWAN','SPXDEMO0000010','NS Marketplace Standard',5.58,2,'Delivering','Recipient reject','NON_BULKY'),
  ];

  static const pretrip = <PreTripEntry>[
    PreTripEntry('TRI IRWAN','Rider','Fit'),
    PreTripEntry('M. SYAWALUDIN PRATAMA','Rider','Fit'),
    PreTripEntry('RIDHO AGUSTIAN','Rider','Fit'),
    PreTripEntry('DIKI HERMANSYAH','Rider','Belum Isi'),
    PreTripEntry('FIQI ARIANTO','Rider','Belum Isi'),
    PreTripEntry('MUHAMMAD WANDA ARYA','Driver','Belum Isi'),
    PreTripEntry('ADRIAN KUSWONDO','Driver','Belum Isi'),
    PreTripEntry('HALIMAN','Driver','Belum Isi'),
  ];

  static const weeklyTasks = <String>[
    'Cek Backlog', 'Cek data delivered rider', 'Monitoring Productivity Rider & Operator',
    'Cek STD daily Riau 3', 'Update monitoring target rider', 'Update Daily Active',
    'Update Productivity OPR', 'Cek assign RR', 'Review hambatan rute',
    'Submit LH trip slot 1', 'Submit LH trip slot 2', 'Cek LMHub_LHArrived',
    'Cek paket stuck part 2 09.00', 'Cek Standardization – RIAU 7',
  ];
}
