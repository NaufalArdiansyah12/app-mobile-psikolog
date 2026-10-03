import base64
import time
import random
import json
import re
import html as html_parser
import urllib.request
import urllib.parse
import urllib.error
from typing import Dict, Any, Optional
from app.core.config import MIDTRANS_SERVER_KEY, MIDTRANS_IS_PRODUCTION

class MidtransService:
    @staticmethod
    def get_base_url() -> str:
        if MIDTRANS_IS_PRODUCTION:
            return "https://api.midtrans.com/v2"
        return "https://api.sandbox.midtrans.com/v2"

    @staticmethod
    def get_auth_header() -> Optional[Dict[str, str]]:
        if not MIDTRANS_SERVER_KEY:
            return None
        encoded = base64.b64encode(f"{MIDTRANS_SERVER_KEY}:".encode("utf-8")).decode("utf-8")
        return {
            "Authorization": f"Basic {encoded}",
            "Content-Type": "application/json",
            "Accept": "application/json"
        }

    @classmethod
    def create_charge(
        cls,
        order_id: str,
        gross_amount: int,
        payment_type: str = "bank_transfer",
        bank: str = "bca",
        customer_name: str = "Pasien Havenly",
        customer_email: str = "pasien@mindpal.id"
    ) -> Dict[str, Any]:
        """Request charge ke Midtrans Core API (dengan fallback sandbox generator jika key kosong)."""
        auth_header = cls.get_auth_header()

        # Format body Midtrans Core API
        payload: Dict[str, Any] = {
            "transaction_details": {
                "order_id": order_id,
                "gross_amount": gross_amount
            },
            "customer_details": {
                "first_name": customer_name,
                "email": customer_email
            }
        }

        bank_clean = (bank or "bca").lower()

        if payment_type == "qris":
            payload["payment_type"] = "qris"
            payload["qris"] = {"acquirer": "gopay"}
        elif bank_clean == "mandiri":
            payload["payment_type"] = "echannel"
            payload["echannel"] = {
                "bill_info1": "Konseling Havenly",
                "bill_info2": "Sesi Spesialis"
            }
        else: # bca, bni, bri, permata
            payload["payment_type"] = "bank_transfer"
            payload["bank_transfer"] = {"bank": bank_clean}

        # Jika ada Midtrans server key, tembak API Midtrans nyata
        if auth_header:
            try:
                url = f"{cls.get_base_url()}/charge"
                req = urllib.request.Request(
                    url,
                    data=json.dumps(payload).encode("utf-8"),
                    headers=auth_header,
                    method="POST"
                )
                with urllib.request.urlopen(req, timeout=10.0) as resp:
                    if resp.status in (200, 201):
                        data = json.loads(resp.read().decode("utf-8"))
                        return cls._parse_midtrans_response(data, payment_type, bank_clean, order_id, gross_amount)
            except urllib.error.HTTPError as e:
                err_body = e.read().decode("utf-8") if e.fp else ""
                print(f"Midtrans Core API error ({e.code}): {err_body}")
            except Exception as e:
                print(f"Midtrans HTTP call exception: {e}")

        # Fallback Mock Midtrans Core API Simulator (Sandbox Ready)
        return cls._generate_mock_charge(order_id, gross_amount, payment_type, bank_clean)

    @classmethod
    def _parse_midtrans_response(
        cls,
        data: Dict[str, Any],
        payment_type: str,
        bank: str,
        order_id: str,
        gross_amount: int
    ) -> Dict[str, Any]:
        va_number = ""
        bill_key = ""
        biller_code = ""
        qr_code_url = ""

        # Extract VA
        va_numbers = data.get("va_numbers", [])
        if va_numbers:
            va_number = va_numbers[0].get("va_number", "")
        elif "permata_va_number" in data:
            va_number = data["permata_va_number"]

        # Extract E-channel Mandiri
        if "bill_key" in data:
            bill_key = data.get("bill_key", "")
            biller_code = data.get("biller_code", "70012")

        # Extract QRIS
        actions = data.get("actions", [])
        for act in actions:
            if act.get("name") == "generate-qr-code":
                qr_code_url = act.get("url", "")
                break

        return {
            "order_id": order_id,
            "gross_amount": gross_amount,
            "payment_type": payment_type,
            "bank": bank,
            "va_number": va_number,
            "bill_key": bill_key,
            "biller_code": biller_code,
            "qr_code_url": qr_code_url,
            "transaction_status": data.get("transaction_status", "pending"),
            "expiry_time": data.get("expiry_time", ""),
            "is_live_midtrans": True
        }

    @classmethod
    def _generate_mock_charge(
        cls,
        order_id: str,
        gross_amount: int,
        payment_type: str,
        bank: str
    ) -> Dict[str, Any]:
        """Menghasilkan nomor VA realistis sesuai format resmi Bank Midtrans."""
        random_suffix = f"{random.randint(10000000, 99999999)}"
        va_number = ""
        bill_key = ""
        biller_code = ""
        qr_code_url = ""

        if payment_type == "qris":
            # QRIS string / sample image
            qr_code_url = f"https://api.sandbox.midtrans.com/v2/qris/{order_id}/qr-code"
        elif bank == "bca":
            va_number = f"70012{random_suffix}"
        elif bank == "bri":
            va_number = f"10777{random_suffix}"
        elif bank == "bni":
            va_number = f"8808{random_suffix}"
        elif bank == "mandiri":
            bill_key = f"998{random.randint(100000, 999999)}"
            biller_code = "70012"
        else:
            va_number = f"88888{random_suffix}"

        return {
            "order_id": order_id,
            "gross_amount": gross_amount,
            "payment_type": payment_type,
            "bank": bank,
            "va_number": va_number,
            "bill_key": bill_key,
            "biller_code": biller_code,
            "qr_code_url": qr_code_url,
            "transaction_status": "pending",
            "expiry_time": f"{int(time.time()) + 86400}",
            "is_live_midtrans": False
        }

    @classmethod
    def simulate_payment_settlement(cls, order_id: str) -> bool:
        """Trigger simulasi pembayaran langsung ke Midtrans Simulator agar status order berubah menjadi settlement."""
        auth_header = cls.get_auth_header()
        if not auth_header:
            return False

        try:
            # 1. Ambil detail transaksi dari Midtrans API
            status_url = f"{cls.get_base_url()}/{order_id}/status"
            req = urllib.request.Request(status_url, headers=auth_header)
            with urllib.request.urlopen(req, timeout=10.0) as resp:
                m_data = json.loads(resp.read().decode("utf-8"))

            t_status = m_data.get("transaction_status")
            if t_status == "settlement":
                return True

            p_type = m_data.get("payment_type", "")
            gross_amt = str(m_data.get("gross_amount", "250000.00"))

            # 2. Tembak payment simulator sesuai tipe pembayaran
            if p_type == "bank_transfer":
                va_list = m_data.get("va_numbers", [])
                bank = va_list[0].get("bank", "").lower() if va_list else ""
                va_num = va_list[0].get("va_number", "") if va_list else ""
                if not bank and "permata_va_number" in m_data:
                    bank = "permata"
                    va_num = m_data.get("permata_va_number", "")

                if bank == "bca":
                    inq_data = urllib.parse.urlencode({"va_number": va_num}).encode("utf-8")
                    req_inq = urllib.request.Request("https://simulator.sandbox.midtrans.com/bca/va/inquiry", data=inq_data, method="POST")
                    with urllib.request.urlopen(req_inq, timeout=10.0) as resp_inq:
                        html = resp_inq.read().decode("utf-8")
                        c_code = re.search(r'name=\"company_code\"\s+value=\"([^\"]+)\"', html)
                        c_num = re.search(r'name=\"customer_number\"\s+value=\"([^\"]+)\"', html)
                        c_name = re.search(r'name=\"customer_name\"\s+value=\"([^\"]+)\"', html)
                        pay_data = urllib.parse.urlencode({
                            "company_code": c_code.group(1) if c_code else "16355",
                            "customer_number": c_num.group(1) if c_num else va_num,
                            "customer_name": c_name.group(1) if c_name else "Pasien Havenly",
                            "currency_code": "IDR",
                            "total_amount": gross_amt
                        }).encode("utf-8")
                        req_pay = urllib.request.Request("https://simulator.sandbox.midtrans.com/bca/va/payment", data=pay_data, method="POST")
                        urllib.request.urlopen(req_pay, timeout=10.0)
                elif bank == "bni":
                    pay_data = urllib.parse.urlencode({
                        "va_number": va_num,
                        "total_amount": str(int(float(gross_amt)))
                    }).encode("utf-8")
                    req_pay = urllib.request.Request("https://simulator.sandbox.midtrans.com/bni/va/payment", data=pay_data, method="POST")
                    urllib.request.urlopen(req_pay, timeout=10.0)
                elif bank in ("bri", "permata", "cimb"):
                    pay_data = urllib.parse.urlencode({
                        "bank": bank.upper(),
                        "virtualAccountName": "Pasien Havenly",
                        "vaNumber": va_num,
                        "amount": gross_amt
                    }).encode("utf-8")
                    req_pay = urllib.request.Request("https://simulator.sandbox.midtrans.com/openapi/va/payment", data=pay_data, method="POST")
                    urllib.request.urlopen(req_pay, timeout=10.0)

            elif p_type == "echannel":
                b_key = m_data.get("bill_key", "")
                b_code = m_data.get("biller_code", "70012")
                pay_data = urllib.parse.urlencode({
                    "bank": "MANDIRI",
                    "virtualAccountName": "Total",
                    "vaNumber": f"{b_code}{b_key}",
                    "amount": gross_amt
                }).encode("utf-8")
                req_pay = urllib.request.Request("https://simulator.sandbox.midtrans.com/openapi/va/payment", data=pay_data, method="POST")
                urllib.request.urlopen(req_pay, timeout=10.0)

            elif p_type == "qris":
                qr_url = ""
                for act in m_data.get("actions", []):
                    if "qr-code" in act.get("name", ""):
                        qr_url = act.get("url", "")
                if not qr_url and m_data.get("transaction_id"):
                    qr_url = f"https://api.sandbox.midtrans.com/v2/qris/{m_data.get('transaction_id')}/qr-code"

                if qr_url:
                    data = urllib.parse.urlencode({"qrCodeUrl": qr_url}).encode("utf-8")
                    req_scan = urllib.request.Request("https://simulator.sandbox.midtrans.com/v2/qris/payment", data=data, method="POST")
                    with urllib.request.urlopen(req_scan, timeout=10.0) as resp_scan:
                        html_qris = resp_scan.read().decode("utf-8")
                        ref_match = re.search(r'name=\"referenceId\"\s+type=\"hidden\"\s+value=\"([^\"]+)\"', html_qris)
                        explore_match = re.search(r'name=\"exploreData\"\s+type=\"hidden\"\s+value=\"([^\"]+)\"', html_qris)
                        if ref_match and explore_match:
                            ref_id = ref_match.group(1)
                            explore_data = html_parser.unescape(explore_match.group(1))
                            pay_data = urllib.parse.urlencode({
                                "referenceId": ref_id,
                                "exploreData": explore_data
                            }).encode("utf-8")
                            req_gopay = urllib.request.Request("https://simulator.sandbox.midtrans.com/v2/qris/payment/gopay", data=pay_data, method="POST")
                            urllib.request.urlopen(req_gopay, timeout=10.0)

            return True
        except Exception as e:
            print(f"Midtrans simulate payment settlement error: {e}")
            return False
