--=== Kiem tra du lieu co null hay khong?
Select a.ngay_tao, a.TD_TH, count(*)sl From dhsx.v_ghtt_ipcc@dataguard a Where to_char(a.ngay_tao, 'yyyymm') = 202409 and a.TG_DT is null Group by a.ngay_tao, a.TD_TH;

Select to_date(a.TD_TH, 'dd/mm/yyyy') TONGDAI_THUCHIEN, sum(a.TG_DT) THOIGIAN_DAMTHOAI
From dhsx.v_ghtt_ipcc@dataguard a Where to_char(to_date(a.TD_TH, 'dd/mm/yyyy'), 'yyyymm') = 202409 Group by a.TD_TH Order by TD_TH;

--====================================================================================================--
--===== CHI TIẾT =====--
--====================================================================================================--
Select * From ttkd_bsc.ktdt_ct_ipcc_obghtt_talktime Where thang = to_char(trunc(sysdate, 'month')-1, 'yyyymm');
--Delete From ttkd_bsc.ktdt_ct_ipcc_obghtt_talktime Where thang = to_char(trunc(sysdate, 'month')-1, 'yyyymm');
--Commit;
Insert Into ttkd_bsc.ktdt_ct_ipcc_obghtt_talktime
    with --=== Nhân vien OB
		nv_ipcc as (	Select a.nguoidung_id, a.user_ipcc, b.nhanvien_id, c.ma_nv
						From admin.nguoidung_ipcc@dataguard a
						Join admin.v_nguoidung@dataguard b on a.nguoidung_id = b.nguoidung_id
						Join admin.v_nhanvien@dataguard c on b.nhanvien_id = c.nhanvien_id
				   )
		,
		--=== Thoi gian OB - TG_DT (giây)
		ipcc as (	select a.ob_id, ngay_tao, a.thuebao_id, ma_tb, LOAITB_ID, TOCDO_ID, a.KHACHHANG_ID, THANHTOAN_ID
							, NGAY_BDDC, NGAY_KTDC, CUOC_DC, SO_THANGDC, CHITIETKM_ID, SL_DATCOC, MATB_PHU, TRANGTHAI_OB
							, to_date(a.TD_TH, 'dd/mm/yyyy') TD_TH, TD_BD, TD_KT, TG_DC, TG_HD, TG_GM
							, TG_DT																									-- thời gian đàm thoại ==> tính lương
							, a.MA_ND
							, row_number() over (partition by thuebao_id, ma_nd order by ob_id desc) rnk 							-- đã hỏi Học kông cần lọc trùng vì tính tất cả
					from dhsx.v_ghtt_ipcc@dataguard a
					where a.trangthai_ob = 'SUCCESS'																				-- cuộc gọi thành công 
						  and to_char(to_date(a.TD_TH, 'dd/mm/yyyy'), 'yyyymm') = to_char(trunc(sysdate, 'month')-1, 'yyyymm')		-- lấy theo thời gian tổng đài thực hiện
						  --and a.tg_dt > 10																						-- 15/07/2024 P.NS đã chỉ đạo bỏ cuộc gọi trên 10s ( Lấy all )
				)
    Select cast(202409 as number(6)) thang, a.ob_id, a.ngay_tao, a.thuebao_id, a.ma_tb, a.loaitb_id, a.tocdo_id, a.khachhang_id
           , a.thanhtoan_id, a.NGAY_BDDC, a.NGAY_KTDC, a.CUOC_DC, a.SO_THANGDC, a.CHITIETKM_ID, a.SL_DATCOC
           , substr(a.MATB_PHU, 1, 500)MATB_PHU																						-- không quan trọng, cắt còn 500 ký tự
           , a.TRANGTHAI_OB
           , a.TD_TH, a.TD_BD, a.TD_KT, a.TG_DC, a.TG_HD, a.TG_GM, a.TG_DT, a.ma_nd
		   , c.nhanvien_id, c.ma_nv
		   , nv.ma_to, nv.ma_pb
    From ipcc a
    Left join nv_ipcc c on a.ma_nd = c.user_ipcc
    Left join ttkd_bsc.nhanvien nv On nv.thang = to_char(trunc(sysdate, 'month')-1, 'yyyymm') and nv.donvi = 'TTKD' and c.ma_nv = nv.ma_nv
;
Commit;
--====================================================================================================--
--==== KIEM TRA DU NGAY THUC HIEN HAY KHONG => OK đủ ngày từ 01 đến 31
Select td_th, count(*)SL, sum(TG_DT)TG_DT, Round(sum(TG_DT)/60,2)TG_PHUT
From ttkd_bsc.ktdt_ct_ipcc_obghtt_talktime
Where thang = to_char(trunc(sysdate, 'month')-1, 'yyyymm')
Group by td_th Order by td_th;
--====================================================================================================--


--====================================================================================================--
--===== UP ID88 - CHI TIET - Lưu ý dấu ' thì them 1 dau ' => '' không phải " 
Select * From
(
    Select a.*, nv.ten_nv, nv.ma_to, nv.ten_to, nv.ma_pb, nv.ten_pb
    From (
            Select THANG, OB_ID
                , to_char(NGAY_TAO, ''dd/mm/yyyy'') NGAY_TAO
                , THUEBAO_ID, MA_TB
                , to_char(NGAY_BDDC, ''dd/mm/yyyy'') NGAY_BDDC
                , to_char(NGAY_KTDC, ''dd/mm/yyyy'') NGAY_KTDC
                , CUOC_DC, SO_THANGDC, CHITIETKM_ID, SL_DATCOC, MATB_PHU
                , TRANGTHAI_OB
                , to_char(TD_TH, ''dd/mm/yyyy'') TD_THUCHIEN
                , TD_BD TD_BatDau
                , TD_KT TD_KetThuc
                , TG_DC TG_DOCHUONG
                , TG_HD TG_TRONGHANGDOI
                , TG_GM TG_GIUMAY
                , TG_DT TG_DAMTHOAI_GIAY
                , MA_ND, MA_NV
            From ttkd_bsc.ktdt_ct_ipcc_obghtt_talktime
        ) a
    Left join ttkd_bsc.nhanvien nv On nv.thang = 202409 and nv.donvi = ''TTKD'' and nv.ma_nv = a.ma_nv
)
--====================================================================================================--

--===== UP ID88 - PHÒNG - Lưu ý dấu ' thì them 1 dau ' => '' không phải " 
Select * From 
(
	Select a.THANG, a.MA_PB, (Select TEN_PB from ttkd_bsc.dm_phongban where ma_pb = a.ma_pb)TEN_PB
		   , sum(a.TG_DT)TG_DAMTHOAI_GIAY
		   , Round(sum(a.TG_DT)/60,2)TG_DAMTHOAI_PHUT
	From ttkd_bsc.ktdt_ct_ipcc_obghtt_talktime a
	Where a.ma_pb in (''VNP0701400'',''VNP0701800'',''VNP0702100'',''VNP0701300'',''VNP0702200'',''VNP0701100'',''VNP0701600'',''VNP0701500'',''VNP0701200'')
	Group by a.THANG, a.MA_PB
)
;
--====================================================================================================--