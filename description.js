'use strict';

class QuanLyGoi {
    constructor() {
        this.baseUrl = window.location.protocol + '//' + window.location.hostname;
        this.khoiTaoSuKien();
    }

    // Lấy phiên bản iOS
    static layPhienBaniOS() {
        const match = navigator.appVersion.match(/OS (\d+_\d+(?:_\d+)?)/);
        return match ? match[1].replace(/_/g, '.') : null;
    }

    // Khởi tạo các sự kiện
    khoiTaoSuKien() {
        document.addEventListener('DOMContentLoaded', () => {
            this.thietLapLienKetUngHo();
            this.hienThiNutThemKhoNeuKhongPhaiCydia();
            this.taiThongTinGoi();
        });

        document.addEventListener('DOMContentLoaded', function() {
            // Lấy thông tin gói từ URL (ví dụ: description.html?id=com.example.package)
            const urlParams = new URLSearchParams(window.location.search);
            const packageId = urlParams.get('id');
        
            // Hiển thị ID gói (hoặc tải thông tin từ server nếu cần)
            document.getElementById('package-id').textContent = packageId;
        });
    }

    // Thiết lập liên kết ủng hộ
    thietLapLienKetUngHo() {
        const nutUngHo = document.getElementById('dnt');
        if (nutUngHo) {
            nutUngHo.addEventListener('click', () => {
                document.getElementById('dnt_txt').innerHTML = 
                    'Bạn có thể ủng hộ qua PayPal: contact@romlayvn.dev';
            });
        }
    }

    // Hiển thị nút "Thêm Kho" nếu không phải Cydia
    hienThiNutThemKhoNeuKhongPhaiCydia() {
        if (!navigator.userAgent.includes('Cydia')) {
            document.getElementById('showAddRepo_')?.classList.remove('hidden');
            document.getElementById('showAddRepoUrl_')?.classList.remove('hidden');
        }
    }

    // Tải thông tin gói
    async taiThongTinGoi() {
        try {
            const urlParts = window.location.href.split('description.html?id=');
            if (urlParts.length !== 2) return;

            const response = await fetch(
                `${this.baseUrl}/packageInfo/${urlParts[1]}`, 
                { cache: 'no-store' }
            );
            
            if (!response.ok) throw new Error('Không thể tải thông tin gói');
            
            const data = await response.json();
            this.capNhatGiaoDien(data);
        } catch (error) {
            this.xuLyLoi(error);
        }
    }

    // Cập nhật giao diện với dữ liệu gói
    capNhatGiaoDien(data) {
        const elements = {
            name: ['name', 'name_'],
            desc_short: ['desc_short', 'desc_short_'],
            desc_long: ['desc_long', 'desc_long_'],
            warning: ['warning', 'warning_'],
            changelog: ['changelog', 'changelog_'],
            screenshot: ['screenshot', 'screenshot_'],
            compatitle: ['compatitle', 'compatitle_']
        };

        // Cập nhật tiêu đề trang
        if (data.name) document.title = data.name;

        // Cập nhật từng phần tử nếu có dữ liệu
        Object.entries(elements).forEach(([key, [contentId, containerId]]) => {
            if (data[key]) {
                document.getElementById(contentId)?.innerHTML = data[key];
                document.getElementById(containerId)?.classList.remove('hidden');
            }
        });

        // Hiển thị thông tin tương thích iOS
        if (data.compatitle) {
            const phienBanHienTai = QuanLyGoi.layPhienBaniOS();
            if (phienBanHienTai) {
                const phanTuiOS = document.getElementById('your_ios');
                if (phanTuiOS) {
                    phanTuiOS.innerHTML = `iOS hiện tại: ${phienBanHienTai}`;
                    phanTuiOS.classList.remove('hidden');
                }
            }
        }

        // Hiển thị chỉ báo mã nguồn mở nếu có
        if (data.open === true) {
            document.getElementById('is_open_source_')?.classList.remove('hidden');
        }

        // Ẩn thanh trạng thái đang tải
        document.getElementById('tweakStatusInfo')?.classList.add('hidden');
    }

    // Xử lý lỗi
    xuLyLoi(error) {
        const phanTuLoi = document.getElementById('errorInfo');
        if (phanTuLoi) {
            phanTuLoi.innerHTML = 'Không thể tải thông tin gói. Vui lòng thử lại sau.';
            phanTuLoi.classList.remove('hidden');
        }
        console.error('Lỗi khi tải thông tin gói:', error);
    }

    // Tải cập nhật mới
    async taiCapNhatMoi() {
        try {
            const response = await fetch(`${this.baseUrl}/last.updates`, { cache: 'no-store' });
            if (!response.ok) throw new Error('Không thể tải cập nhật');

            const updates = await response.json();
            this.hienThiCapNhatMoi(updates);
        } catch (error) {
            console.error('Lỗi khi tải cập nhật:', error);
        }
    }

    // Hiển thị cập nhật mới
    hienThiCapNhatMoi(updates) {
        const danhSachCapNhat = document.getElementById('updates');
        if (!danhSachCapNhat) return;

        const laCydia = navigator.userAgent.includes('Cydia');
        const htmlCapNhat = updates.map(capNhat => {
            const url = laCydia 
                ? `cydia://package/${capNhat.package}`
                : `${this.baseUrl}/description.html?id=${capNhat.package}`;
            
            return `
                <li>
                    <a href="${url}" target="_blank">
                        <img class="icon" src="tweak.png" alt="${capNhat.name}"/>
                        <label>${capNhat.name} v${capNhat.version}</label>
                    </a>
                </li>
            `;
        }).join('');

        danhSachCapNhat.innerHTML = htmlCapNhat;
        document.getElementById('updates_')?.classList.remove('hidden');
    }
}

// Khởi tạo trình quản lý gói
const quanLyGoi = new QuanLyGoi();