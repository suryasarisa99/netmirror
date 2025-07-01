
// class CookiesData {
//   String? tHashT;
//   DateTime? tHashTExpire;

//   String? addhash;
//   String? resourceKey;
//   DateTime? resourceExpire;

//   CookiesData({
//     required this.tHashT,
//     required this.tHashTExpire,
//     required this.addhash,
//     required this.resourceKey,
//     required this.resourceExpire,
//   });

//   factory CookiesData.empty() {
//     return CookiesData(
//       tHashT: null,
//       tHashTExpire: null,
//       addhash: null,
//       resourceKey: null,
//       resourceExpire: null,
//     );
//   }

//   factory CookiesData.parse(String? json) {
//     if (json == null || json.isEmpty) return CookiesData.empty();
//     try {
//       final data = jsonDecode(json);
//       return CookiesData(
//         tHashT: data["tHashT"],
//         tHashTExpire: data["tHashTExpire"] == null
//             ? null
//             : DateTime.parse(data["tHashTExpire"]),
//         addhash: data["addhash"],
//         resourceKey: data["resourceKey"],
//         resourceExpire: data["resourceExpire"] == null
//             ? null
//             : DateTime.parse(data['resourceExpire']),
//       );
//     } catch (e) {
//       print("Error parsing JSON: $e");
//       return CookiesData.empty();
//     }
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       "tHashT": tHashT,
//       "tHashTExpire": tHashTExpire?.toIso8601String(),
//       "addhash": addhash,
//       "resourceKey": resourceKey,
//       "resourceExpire": resourceExpire?.toIso8601String(),
//     };
//   }

//   setTHashT(String tHashT) {
//     this.tHashT = tHashT;
//     tHashTExpire = DateTime.now()
//         .add(const Duration(hours: 18, minutes: 30)); // expires: 18h:30m
//   }

//   setResourceKey(String resourceKey) {
//     this.resourceKey = resourceKey;
//     resourceExpire = DateTime.now().add(const Duration(days: 1));
//   }

//   setAddHash(String addhash, DateTime addhashExpire) {
//     this.addhash = addhash;
//   }

//   bool get isExpired {
//     log("key: $tHashT expire: $tHashTExpire");
//     return tHashT == null ||
//         tHashTExpire == null ||
//         tHashT!.isEmpty ||
//         tHashTExpire!.isBefore(DateTime.now());
//   }

//   bool get isValid => !isExpired;

//   bool get isValidResourceKey =>
//       resourceKey != null &&
//       resourceExpire != null &&
//       resourceKey!.isNotEmpty &&
//       resourceKey!.length > 5 &&
//       resourceExpire!.isAfter(DateTime.now());
// }

// class CookiesProvider extends StateNotifier<CookiesData> {
//   CookiesProvider() : super(CookiesData.empty());

//   void initial() async {
//     log("initited");
//     state = CookiesData.parse(sp!.getString("cookies"));
//   }

//   set resourceKey(String? resourceKey) {
//     state.setResourceKey(resourceKey!);
//     save();
//   }

//   set tHashT(String? tHashT) {
//     state.setTHashT(tHashT!);
//     save();
//   }

//   void save() {
//     log("provider resource key: ${state.resourceKey}, ${state.tHashTExpire}");
//     sp!.setString("cookies", jsonEncode(state.toJson()));
//   }

//   Future<void> validate() async {
//     if (state.isExpired) {
//       log("thasht is expired");
//       final addhash = await getInitial();
//       print("addhash: $addhash");
//       await openAdd(addhash);
//       print("add opened");
//       await Future.delayed(const Duration(seconds: 35), () async {
//         final tHashT = await verifyAdd(addhash);
//         log("new thash is $tHashT");
//         if (tHashT != null) {
//           log("t_hash_t: $tHashT");
//           this.tHashT = tHashT;
//         } else {
//           log("thash is null");
//         }
//       });
//     } else {
//       log("t_hash_t: ${state.tHashT}");
//       return;
//     }
//   }

//   String? get tHashT => state.tHashT;
//   String? get resourceKey => state.resourceKey;
//   CookiesData get mystate => state;
// }

// final cookiesProvider = StateNotifierProvider<CookiesProvider, CookiesData>(
//     (ref) => CookiesProvider());
