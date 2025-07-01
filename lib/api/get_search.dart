import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:netmirror/constants.dart';
import 'package:netmirror/data/cookies_manager.dart';
import 'package:netmirror/models/netmirror/netmirror_model.dart';

Future<NmSearchResults> getNmSearch(String query, {OTT ott = OTT.none}) async {
  // final tHashT = await CookiesManager.validTHashT;
  final tHashT = CookiesManager.tHashT;
  final headers = {
    'accept': '*/*',
    'accept-language': 'en-US,en;q=0.9',
    'cache-control': 'no-cache',
    'cookie': 't_hash_t=$tHashT;',
    'pragma': 'no-cache',
    'priority': 'u=1, i',
    'referer': '$API_URL/movies',
    'sec-ch-ua':
        '"Google Chrome";v="131", "Chromium";v="131", "Not_A Brand";v="24"',
    'sec-ch-ua-mobile': '?0',
    'sec-ch-ua-platform': '"Linux"',
    'sec-fetch-dest': 'empty',
    'sec-fetch-mode': 'cors',
    'sec-fetch-site': 'same-origin',
    'user-agent':
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
    'x-requested-with': 'XMLHttpRequest',
  };

  final params = {
    's': query,
    't': '1734872866',
  };

  final url = Uri.parse('$API_URL/${ott.url}search.php')
      .replace(queryParameters: params);

  final res = await http.get(url, headers: headers);
  final status = res.statusCode;
  if (status != 200) throw Exception('http.get error: statusCode= $status');
  log("response: ${res.body}");
  return NmSearchResults.fromJson(jsonDecode(res.body), ott, query);
}




//   {
//     "status": "y",
//     "d_lang": "hin",
//     "title": "Bhool Bhulaiyaa 2",
//     "year": "2022",
//     "ua": "U\/A 13+",
//     "match": "62% match",
//     "runtime": "2h 21m",
//     "hdsd": "HD",
//     "type": "m",
//     "creator": "",
//     "director": "Anees Bazmee",
//     "writer": "Aakash Kaushik, Farhad Samji",
//     "short_cast": "Tabu, Kartik Aaryan, Kiara Advani, Rajpal Yadav, Sanjay Mishra, Ashwini Kalsekar, Rajesh Sharma, Amar Upadhyay",
//     "cast": "Tabu, Kartik Aaryan, Kiara Advani, Rajpal Yadav, Sanjay Mishra, Ashwini Kalsekar, Rajesh Sharma, Amar Upadhyay",
//     "genre": "Hindi-Language Movies, Bollywood Movies, Comedies, Horror Movies",
//     "thismovieis": "Offbeat, Suspenseful",
//     "m_desc": "Suitable for persons aged 13 and above and under parental guidance for people under age of 13",
//     "m_reason": "violence, threat, mature themes, language, gore",
//     "desc": "When strangers Reet and Ruhan cross paths, their journey leads to an abandoned mansion and a dreaded spirit who has been trapped for 18 years.",
//     "oin": "",
//     "resume": "",
//     "lang": [
//         {
//             "l": "Hindi",
//             "s": "hin"
//         }
//     ],
//     "episodes": [
//         null
//     ],
//     "suggest": [
//         {
//             "id": "81267359"
//         },
//         {
//             "id": "80017528"
//         },
//         {
//             "id": "70052249"
//         },
//         {
//             "id": "81113918"
//         },
//         {
//             "id": "81595543"
//         },
//         {
//             "id": "81382254"
//         },
//         {
//             "id": "70037493"
//         },
//         {
//             "id": "70278990"
//         },
//         {
//             "id": "81029150"
//         },
//         {
//             "id": "70219526"
//         },
//         {
//             "id": "70083535"
//         },
//         {
//             "id": "81722145"
//         }
//     ],
//     "error": null
// }

// {
//     "status": "y",
//     "d_lang": "eng",
//     "title": "Overdose",
//     "year": "2022",
//     "ua": "U\/A 18+ [A]",
//     "match": "IMDb 5.8",
//     "runtime": "1h 59m",
//     "hdsd": "HD",
//     "type": "m",
//     "creator": "",
//     "director": "Olivier Marchal",
//     "writer": "Christophe Gavat, Olivier Marchal, Pierre Pouchairet",
//     "short_cast": "Sofia Essaidi, Assaad Bouab, Alberto Ammann, Nicolas Cazal\u00e9, Nassim Lyes Si Ahmed, Na\u00efma Rodric, Francis Renaud, Kool Shen, Moussa Mansaly, Zo\u00e9 Marchal, Pierre Laplace, S\u00e9bastien Libessart, Olivier Barth\u00e9l\u00e9my, Simon Abkarian, Philippe Corti, Kenza Fortas, Carlos Bardem, Nicolas Maretheu",
//     "cast": "Sofia Essaidi, Assaad Bouab, Alberto Ammann, Nicolas Cazal\u00e9, Nassim Lyes Si Ahmed, Na\u00efma Rodric, Francis Renaud, Kool Shen, Moussa Mansaly, Zo\u00e9 Marchal, Pierre Laplace, S\u00e9bastien Libessart, Olivier Barth\u00e9l\u00e9my, Simon Abkarian, Philippe Corti, Kenza Fortas, Carlos Bardem, Nicolas Maretheu",
//     "genre": "Action, Suspense, International",
//     "thismovieis": "Serious, Thoughtful",
//     "m_desc": "Suitable for ages 18 and older",
//     "m_reason": "violence, sexual content, foul language, nudity, alcohol use, substance use, tobacco depictions",
//     "desc": "[Original Audio in \u201cMultiple Languages\u201d] Sara Bella\u00efche, captain at the judicial police in Toulouse, is investigating a go-fast linked to the murder of two teenagers, a case that Richard Cross, a cop in Paris, is dealing with. Forced to collaborate, Sara and Richard, with diametrically opposed methods, get plunged into a breathless race against the clock from Spain's to France's roads.",
//     "oin": null,
//     "resume": "",
//     "lang": [
//         {
//             "l": "German",
//             "s": "deu"
//         },
//         {
//             "l": "English",
//             "s": "eng"
//         },
//         {
//             "l": "Spanish",
//             "s": "spa"
//         },
//         {
//             "l": "French",
//             "s": "fra"
//         },
//         {
//             "l": "Hindi",
//             "s": "hin"
//         },
//         {
//             "l": "Italian",
//             "s": "ita"
//         },
//         {
//             "l": "Japanese",
//             "s": "jpn"
//         },
//         {
//             "l": "Unknown",
//             "s": "und"
//         },
//         {
//             "l": "Polish",
//             "s": "pol"
//         },
//         {
//             "l": "Portuguese",
//             "s": "por"
//         }
//     ],
//     "langnum": "10",
//     "episodes": [
//         null
//     ],
//     "suggest": [
//         {
//             "id": "0JAYRVT4PBPM7XHUU2ERPMGBIX"
//         },
//         {
//             "id": "0L0IRD03DUJN7C20LI45JP7ZSG"
//         },
//         {
//             "id": "0T40AMJOVIGOGA6RTJGALDI6GZ"
//         },
//         {
//             "id": "0FSE8GW3LLYSQZK9HZ30BY9S2X"
//         },
//         {
//             "id": "0IQWQ73GEIESIAOIHVHX0BR96K"
//         },
//         {
//             "id": "0TZX7PFLL0T2ST6FQN0YECUD1W"
//         }
//     ],
//     "error": null
// }



// curl '$API_URL/pv/search.php?s=hi&t=1734872866' \
//   -H 'accept: */*' \
//   -H 'accept-language: en-US,en;q=0.9' \
//   -H 'cache-control: no-cache' \
//   -H 'cookie: HstCfa1685644=1734857714692; HstCmu1685644=1734857714692; __dtsu=6D0017348577150DD5DE4E7989C802B4; t_hash_t=59a05b117809dbe6e0879acb3cac14c3%3A%3Ad3a5edada67e7cd29383812492e37010%3A%3A1734858307%3A%3Ani; HstCfa1188575=1734858309433; HstCmu1188575=1734858309433; SE81303831=81725711; recentplay=SE81303831; 81725711=188%3A3144; HstCla1685644=1734872710969; HstPn1685644=1; HstPt1685644=3; HstCnv1685644=2; HstCns1685644=3; HstCnv1188575=2; HstCns1188575=2; cf_clearance=KqoiJx2v9X5ODJhTAv.lJ2Rcz4EasgergBfaUMXdWJU-1734872714-1.2.1.1-1n9P9IH3PjZ.eSNmeX.82ILhnyrhgXq.ttU8IoN8eXMWX2nZdskRpsbF8n7Y20TIhoKEX1nPTDPeJEp4d5SYLwKeOhG9ujkNYgDaCjSgavs0WW6xDL9URWykSlJCLtbAKJXhxq68bD0Dv5djYq4MLjUQ8yOK3zfamwa3hUfrFKUs2u4.G8vicZrDOgvNt706CjKMyc4i9Cswgw5VlMuV0_.FO_MSteqxFLCMxzwpViDFNTfQQuc6eLz_XSpztdlMgszX6lHjS1uLSuszF_bww0lQaPznaZeqTZyHi1Trrwe8adIjrvUq6Q9jRK8XUbRplhuhxMTfxyVwGL1RC8CA.R27F5rBUyh7YNV6c6gVM21H1Gh8Sm0.6Zt15_imIYJ5; ott=pv; HstCla1188575=1734872870308; HstPn1188575=3; HstPt1188575=7; t_hash=3869c6772c40634cc4f3226d7cd363de%3A%3A1734873050%3A%3Ani' \
//   -H 'pragma: no-cache' \
//   -H 'priority: u=1, i' \
//   -H 'referer: $API_URL/movies' \
//   -H 'sec-ch-ua: "Google Chrome";v="131", "Chromium";v="131", "Not_A Brand";v="24"' \
//   -H 'sec-ch-ua-mobile: ?0' \
//   -H 'sec-ch-ua-platform: "Linux"' \
//   -H 'sec-fetch-dest: empty' \
//   -H 'sec-fetch-mode: cors' \
//   -H 'sec-fetch-site: same-origin' \
//   -H 'user-agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36' \
//   -H 'x-requested-with: XMLHttpRequest'